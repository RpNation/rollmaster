# frozen_string_literal: true

require "mini_racer"

module Rollmaster
  class DiceEngine
    @mutex = Mutex.new
    @ctx_init = Mutex.new
    @ctx = nil

    def self.protect
      rval = nil
      @mutex.synchronize { rval = yield }
      rval
    end

    def self.roll(*diceRolls)
      result = nil
      protect do
        context = v8
        result = context.call("roll", *diceRolls)
      end
      result
    end

    def self.attach_function(ctx)
      ctx.eval <<~JS
        function roll(...diceRolls) {
          const roller = new rpgDiceRoller.DiceRoller;
          const rolls = roller.roll(...diceRolls);
          return rolls
        }
      JS
    end

    def self.create_context
      # Create a new v8 context. Not exactly happy with starting a new v8 context, but we don't
      # want to share the context between threads. Similarly, no auto disposal mechanism, so we
      # just need to hope the improved user experience is worth the memory usage.
      ctx = MiniRacer::Context.new(timeout: 25_000, ensure_gc_after_idle: 2000)

      ctx.eval("window = globalThis; window.devicePixelRatio = 2;") # hack to make code think stuff is retina

      ctx.attach("rails.logger.info", proc { |err| Rails.logger.info(err.to_s) })
      ctx.attach("rails.logger.warn", proc { |err| Rails.logger.warn(err.to_s) })
      ctx.attach("rails.logger.error", proc { |err| Rails.logger.error(err.to_s) })
      ctx.eval <<~JS
        console = {
          prefix: "[Rollmaster] ",
          log: function(...args){ rails.logger.info(console.prefix + args.join(" ")); },
          warn: function(...args){ rails.logger.warn(console.prefix + args.join(" ")); },
          error: function(...args){ rails.logger.error(console.prefix + args.join(" ")); }
        }
      JS

      # skip transpiler. pre-compiled to UMD, which should cover modern browsers.
      # See https://github.com/dice-roller/rpg-dice-roller/blob/develop/.babelrc
      ctx.load("#{Rails.root}/plugins/rollmaster/public/vendors/math.js")
      ctx.load("#{Rails.root}/plugins/rollmaster/public/vendors/random-js.min.js")
      ctx.load("#{Rails.root}/plugins/rollmaster/public/vendors/rpg-dice-roller.min.js")

      attach_function(ctx)

      ctx
    end

    def self.v8
      return @ctx if @ctx

      @ctx_init.synchronize do
        return @ctx if @ctx
        @ctx = create_context
      end
      @ctx
    end

    def self.reset_context
      @ctx_init.synchronize do
        @ctx&.dispose
        @ctx = nil
      end
    end

    def self.execute_in_context(context, script)
      context.eval(script)
    rescue MiniRacer::RuntimeError => e
      raise "Error executing script: #{e.message}"
    end
  end
end
