# frozen_string_literal: true

RSpec.configure { |c| c.filter_run_when_matching :focus }

RSpec.describe Rollmaster::DiceEngine do
  describe ".roll" do
    it "returns a per-notation ok result for multiple dice rolls" do
      dice_rolls = %w[2d6 1d20]
      result = described_class.roll(*dice_rolls)

      expect(result.size).to eq(dice_rolls.size)
      expect(result).to all(include("ok" => true, "value" => a_kind_of(String)))
    end

    it "returns an error entry instead of raising for an invalid notation" do
      result = described_class.roll("invalid_roll")

      expect(result.size).to eq(1)
      expect(result.first["ok"]).to eq(false)
      expect(result.first["msg"]).to be_present
    end

    it "isolates a bad notation from the others in the same call" do
      result = described_class.roll("2d6", "invalid_roll", "1d20")

      expect(result.map { |r| r["ok"] }).to eq([true, false, true])
    end

    it "returns an empty array when no notations are given" do
      expect(described_class.roll).to eq([])
    end
  end

  describe ".format_notation" do
    it "formats the notation of the dice rolls" do
      dice_rolls = ["{3d8  * 2, 20 /  2d10, 2d10 - d4}     // testing"]
      result = described_class.format_notation(*dice_rolls)

      expect(result.size).to eq(1)
      expect(result.first["ok"]).to eq(true)
      expect(result.first["value"]).to eq("{3d8*2, 20/2d10, 2d10-1d4}") # has stripped whitespace and comments
    end

    it "returns an error entry instead of raising for an invalid notation" do
      result = described_class.format_notation("invalid_notation")

      expect(result.first["ok"]).to eq(false)
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

  describe ".attach_function" do
    it "attaches the roll function to the context" do
      context = MiniRacer::Context.new
      described_class.attach_function(context)

      result = context.eval("typeof roll")
      expect(result).to eq("function")
    end
  end
end
