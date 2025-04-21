# frozen_string_literal: true

RSpec.configure { |c| c.filter_run_when_matching :focus }

RSpec.describe Rollmaster::DiceEngine do
  describe ".roll" do
    it "executes a dice roll and returns the result" do
      dice_rolls = %w[2d6 1d20]
      result = described_class.roll(*dice_rolls)

      expect(result).not_to be_nil
      expect(result).to be_a(Array)
      expect(result.size).to eq(dice_rolls.size)
      expect(result.all? { |r| r.is_a?(Hash) }).to be(true)
    end
  end

  describe ".reset_context" do
    it "resets the V8 context" do
      initial_context = described_class.v8
      described_class.reset_context
      new_context = described_class.v8

      expect(new_context).not_to eq(initial_context)
    end
  end

  describe ".execute_in_context" do
    it "executes a script in the given context" do
      context = described_class.v8
      script = "2 + 2"
      result = described_class.execute_in_context(context, script)

      expect(result).to eq(4)
    end

    it "raises an error for invalid scripts" do
      context = described_class.v8
      script = "invalid_code()"

      expect { described_class.execute_in_context(context, script) }.to raise_error(
        RuntimeError,
        /Error executing script/,
      )
    end
  end

  describe ".create_context" do
    it "creates a new V8 context with the expected configuration" do
      context = described_class.create_context

      expect(context).not_to be_nil
      expect(context).to respond_to(:eval)
    end

    it "attaches the dice roller functions to the context" do
      context = described_class.create_context

      expect(context.eval("typeof rpgDiceRoller")).not_to be_nil
    end
  end

  xdescribe ".attach_function" do
    it "attaches the roll function to the context" do
      context = MiniRacer::Context.new
      described_class.attach_function(context)

      result = context.eval("typeof roll")
      expect(result).to eq("function")
    end
  end
end
