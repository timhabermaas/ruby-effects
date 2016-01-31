require "spec_helper"

describe Eff::FTCQueue do
  describe ".singleton" do
    it "wrapes a single function" do
      queue = Eff::FTCQueue.singleton -> (x) { Eff::Freer.return(x * 2) }
      expect(queue.call(2).value).to eq 4
    end
  end

  describe "#append" do
    context "combining two Pure functions" do
      it "works" do
        q1 = Eff::FTCQueue.singleton(-> (x) { Eff::Freer.return(x * 2) })
        q2 = Eff::FTCQueue.singleton(-> (x) { Eff::Freer.return(x + 1) })
        expect(q1.append(q2).call(2).value).to eq 5
      end
    end

    context "combining Pure and Impure function" do
      it "works" do
        q1 = Eff::FTCQueue.singleton(-> (x) { Eff::Freer.return(x * 2) })
        q2 = Eff::FTCQueue.singleton(-> (x) { Eff.send(x + 1) })
        expect(q1.append(q2).call(2).v).to eq 5
        expect(q2.append(q1).call(2).v).to eq 3
      end
    end

    context "combining Impure functions" do
      it "works" do
        q1 = Eff::FTCQueue.singleton(-> (x) { Eff.send(x * 2) })
        q2 = Eff::FTCQueue.singleton(-> (x) { Eff.send(x + 1) })
        expect(q1.append(q2).call(2).v).to eq 4
        expect(q2.append(q1).call(2).v).to eq 3
      end
    end
  end

  describe "#>> / #snoc" do
    context "combining Pure functions" do
      it "appends the function to the end" do
        queue = Eff::FTCQueue.singleton(-> (x) { Eff::Freer.return(x * 2) }) >> (-> (x) { Eff::Freer.return(x + 1) })
        expect(queue.call(2).value).to eq 5
      end
    end

    context "combining Pure and Impure function" do
      it "appends the function to the end" do
        queue = Eff::FTCQueue.singleton(-> (x) { Eff::Freer.return(x * 3) }) >> (-> (x) { Eff.send(x + 1) })
        expect(queue.call(4).v).to eq 13
      end
    end

    context "combining Impure and Pure function" do
      it "appends the function to the end" do
        queue = Eff::FTCQueue.singleton(-> (x) { Eff.send(x * 3) }) >> (-> (x) { Eff::Freer.return(x + 1) })
        expect(queue.call(4).v).to eq 12
        expect(queue.call(4).k.call(2).value).to eq 3
      end
    end

    context "combining Impure functions" do
      it "appends the function to the end" do
        queue = Eff::FTCQueue.singleton(-> (x) { Eff.send(x * 3) }) >> (-> (x) { Eff.send(x + 1) })
        expect(queue.call(4).v).to eq 12
        expect(queue.call(4).k.call(2).v).to eq 3
      end
    end
  end
end
