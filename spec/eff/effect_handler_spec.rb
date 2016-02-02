require 'spec_helper'

RSpec.describe Eff::EffectHandler do
  describe "without state" do
    describe "handling one effect" do
      let(:inputs) { ["b", "a"] }
      let(:outputs) { [] }

      def handler(effect)
        Eff::EffectHandler.new
          .on_impure(TTY::Get) do |g, k|
            k.call(inputs.pop)
          end
          .on_impure(TTY::Put) do |p, k|
            outputs << p.string
            k.call(nil)
          end
          .run(effect)
      end

      let(:program) {
        TTY.get.bind do |x|
          TTY.put(x + "a") >> TTY.get.bind do |y|
            TTY.put(y + "b") >> Eff::Freer.return(2)
          end
        end
      }

      it "works" do
        result = Eff.run(handler(program))
        expect(outputs).to eq ["aa", "bb"]
        expect(result).to eq 2
      end
    end
  end

  describe "with state" do
    describe "handling one effect" do
      let(:inputs) { ["b", "a"] }
      let(:outputs) { [] }

      def handler(effect)
        state = {
          inputs: ["b", "a"],
          outputs: []
        }
        Eff::EffectHandler.with_state
          .on_impure(TTY::Get) do |g, k, s|
            [k.call(s[:inputs].pop), s]
          end
          .on_impure(TTY::Put) do |p, k, s|
            s[:outputs] << p.string
            [k.call(nil), s]
          end
          .on_pure do |v, s|
            Eff::Freer.return [v, s]
          end
          .run(effect, state)
      end

      let(:program) {
        TTY.get.bind do |x|
          TTY.put(x + "a") >> TTY.get.bind do |y|
            TTY.put(y + "b") >> Eff::Freer.return(2)
          end
        end
      }

      it "passes the state around" do
        x, new_state = Eff.run(handler(program))
        expect(new_state[:outputs]).to eq ["aa", "bb"]
        expect(x).to eq 2
      end
    end
  end
end
