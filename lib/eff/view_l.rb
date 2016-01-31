module Eff
  class ViewL
    class TOne < ViewL
      attr_reader :k

      def initialize(k)
        @k = k
      end
    end

    class TAppend < ViewL
      attr_reader :k, :queue

      def initialize(k, queue)
        @k, @queue = k, queue
      end
    end
  end
end
