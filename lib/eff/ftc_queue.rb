require 'eff/view_l'

module Eff
  class FTCQueue
    def append(other)
      Node.new(self, other)
    end

    def snoc(f)
      Node.new(self, Leaf.new(f))
    end

    def qcomp(f)
      lambda { |x| f.call(self.qapp(x)) }
    end

    def qapp(x)
      foo = self.tviewl
      case foo
      when ViewL::TOne
        foo.k.call(x)
      when ViewL::TAppend
        bind = lambda { |e, k|
          case e
          when Pure
            k.qapp(e.value)
          when Impure
            Impure.new(e.v, e.k.append(k))
          end
        }
        bind.call(foo.k.call(x), foo.queue)
      end
    end
    alias_method :call, :qapp

    class Leaf < FTCQueue
      attr_reader :v

      def initialize(v)
        @v = v
      end

      def tviewl
        ViewL::TOne.new(@v)
      end
    end

    class Node < FTCQueue
      attr_reader :a, :b

      def initialize(a, b)
        @a, @b = a, b
      end

      def tviewl
        go = lambda { |t1, t2|
          case t1
          when Leaf
            ViewL::TAppend.new(t1.v, t2)
          when Node
            go.call(t1.a, Node.new(t1.b, t2))
          end
        }
        go.call(@a, @b)
      end
    end

    def self.singleton(v)
      Leaf.new(v)
    end
  end
end
