module RMath
  class DimensionError < StandardError
  end
  class NotSizedError < StandardError
  end

  module Expression
    def * rhs
      ProductChain.new [self, rhs]
    end

    def transpose
      TransposeFunction.new self
    end

  end

  class Numeric
    include Expression
    def transpose
      self
    end
  end

  class SequentialNumberer
    def initialize
      @iter = 100000.times
    end

    def next_num
      @iter.next
    end

    def next_name
      "temp%03d" % next_num
    end
  end

  class Matrix 
    include Expression

    attr_reader :name
  
    def initialize name, rows=nil, cols=nil
      @name = name
      @rows = rows
      @cols = cols
    end
  
    def declaration
      "double *#{name};"
    end

    def rows
      @rows || raise(NotSizedError, "No rows defined")
    end

    def cols
      @cols || raise(NotSizedError, "No cols defined")
    end

    def allocated?
      !!@allocated
    end

    def malloc
      @allocated = true
      "#{name} = malloc(#{rows * cols} * sizeof (*#{name}));"
    end

    def free
      raise NotAllocatedError, "#{name.inspect} not malloced" unless allocated?
      "free(#{name});"
    end
  
    def unif_fill lower, upper
      "for (int i = 0; i < #{rows * cols}; i++)\n" +
      "  #{name}[i] = unif(#{lower}, #{upper});"
    end
  
    def display
      "printmat(#{name.inspect}, #{name}, #{rows}, #{cols});"
    end

    def [] i, j
      "#{name}[#{i} + (#{j}) * #{rows}]"
    end


    def inspect
      "#<Matrix #{@name.inspect} rows=#{@rows.inspect} cols=#{@cols.inspect}>"
    end
  end

  class TransposeFunction
    include Expression

    attr_reader :x

    def initialize x
      @x = x
    end

    def [] i, j
      x[j, i]
    end

    def rows
      x.cols
    end

    def cols
      x.rows
    end

    def transpose
      x
    end
  end

  class TempMatrix < Matrix
    def initialize rows, cols
      @@seq_numberer ||= SequentialNumberer.new
      super @@seq_numberer.next_name, rows, cols
    end
  end

  class ProductChain
    include Expression

    attr_reader :chain

    def initialize chain
      @chain = chain
    end

    def * rhs
      case rhs
      when ProductChain
        ProductChain.new chain + rhs.chain
      when Expression
        ProductChain.new chain + [rhs]
      else
        raise TypeError, "can't multiply with #{rhs.inspect}"
      end
    end

    def rows
      chain.first.rows
    end

    def cols
      chain.last.cols
    end

    def length
      chain.length
    end

    
    def into target
      if length == 2
        into_two target
      elsif length <= 1
        raise NotImplementedError
      else
        op1 = chain[0]
        multiplicands = chain.drop(1)
        op2 = multiplicands.shift
        code = []
        loop do
          unless multiplicands.any?
            prod = target
          else
            prod = TempMatrix.new op1.rows, op2.cols
            code << prod.declaration
            code << prod.malloc
          end

          p [op1, op2, prod]
          code << (op1*op2).into_two(prod)
          if op1.is_a?(TempMatrix)
            code << op1.free
          end
          break if multiplicands.empty?
          op1, op2 = prod, multiplicands.shift
        end
        p code
        code.join "\n"
      end
    end

    protected
    def into_two target
      raise unless length == 2
      a, b = chain
      unless target.rows == a.rows && target.cols == b.cols
        raise DimensionError, "incompatible matrix dimensions"
      end

      i, j, k = %w{i j k}

      <<-EOS
for (int i = 0; i < #{rows}; i++) {
    for (int j = 0; j < #{cols}; j++) {
        #{target[i, j]} = 0;
        for (int k = 0; k < #{a.cols}; k++)
            #{target[i, j]} += #{a[i, k]} * #{b[k, j]};
    }
}
      EOS
    end
  end
end
