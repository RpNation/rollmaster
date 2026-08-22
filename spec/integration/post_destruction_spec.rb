# frozen_string_literal: true

RSpec.describe "Post destruction", type: :integration do
  fab!(:admin)

  before do
    enable_current_plugin
    Jobs.run_immediately!
  end

  def process_post(post)
    cpp = CookedPostProcessor.new(post)
    cpp.post_process
    post.update_column(:cooked, cpp.html)
    cpp
  end

  it "keeps rolls when a post is trashed" do
    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save
    process_post(post)
    roll = ::Rollmaster::Roll.find_by!(post_id: post.id)

    PostDestroyer.new(admin, post).destroy

    expect(post.reload).to be_trashed
    expect(::Rollmaster::Roll.where(post_id: post.id)).to contain_exactly(roll)
  end

  it "keeps rolls when a trashed post is recovered" do
    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save
    process_post(post)
    roll = ::Rollmaster::Roll.find_by!(post_id: post.id)

    PostDestroyer.new(admin, post).destroy
    PostDestroyer.new(admin, post).recover

    expect(post.reload).not_to be_trashed
    expect(::Rollmaster::Roll.where(post_id: post.id)).to contain_exactly(roll)
  end

  it "deletes rolls when a post is permanently destroyed" do
    post = Fabricate(:post, raw: "[roll]2d6[/roll]")
    post.save
    process_post(post)
    roll = ::Rollmaster::Roll.find_by!(post_id: post.id)
    post_id = post.id

    PostDestroyer.new(admin, post, force_destroy: true).destroy

    expect(Post.with_deleted.find_by(id: post_id)).to be_nil
    expect(::Rollmaster::Roll.where(id: roll.id)).to be_empty
  end
end
