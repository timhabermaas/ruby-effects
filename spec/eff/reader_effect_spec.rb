require 'spec_helper'

RSpec.describe "reader effect" do
  module ReaderEff
    class Reader
    end

    def self.ask
      Eff.send Reader.new
    end

    def self.run(context, effect)
      Eff.handle_relay(-> (e) { Eff::Freer.return e },
                       { ReaderEff::Reader => -> (r, k) {k.call(context)} }
                      )[effect]
    end
  end

  let(:run) { -> (input) { Eff.run(ReaderEff.run(input, program)) } }

  context "given simple ask program" do
    let(:program) { ReaderEff::ask }

    it "behaves like the identity function" do
      expect(run[10]).to eq 10
    end
  end

  context "given program which multiplies context" do
    let(:program) { ReaderEff::ask.bind { |e| Eff::Freer.return(e * 2) } }

    it "behaves like the (* 2) function" do
      expect(run[10]).to eq 20
    end
  end
end
