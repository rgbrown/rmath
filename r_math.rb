module RMath
  class DimensionError < StandardError
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
    attr_reader :name, :rows, :cols
  
    def initialize name, rows, cols
      @name = name
      @rows = rows
      @cols = cols
    end
  
    def declaration
      "double *#{name};"
    end
  
    def malloc
      "#{name} = malloc(#{rows * cols} * sizeof (*#{name}));"
    end
  
    def unif_fill lower, upper
      "for (int i = 0; i < #{rows * cols}; i++)\n" +
      "  #{name}[i] = unif(#{lower}, #{upper});"
    end
  
    def print
      "printmat(#{name.inspect}, #{name}, #{rows}, #{cols});"
    end

    def [] i, j
      "#{name}[#{i} + (#{j}) * #{rows}]"
    end

    def * rhs
      ProductChain.new [self, rhs]
    end

    def inspect
      "#<Matrix #{name.inspect} rows=#@rows cols=#@cols>"
    end
  end

  class TempMatrix < Matrix
    def initialize rows, cols
      @@seq_numberer ||= SequentialNumberer.new
      super @@seq_numberer.next_name, rows, cols
    end
  end

  class ProductChain
    attr_reader :chain

    def initialize chain
      @chain = chain
    end

    def * rhs
      case rhs
      when ProductChain
        ProductChain.new chain + rhs.chain
      when Matrix, Numeric 
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

        until multiplicands.empty? do
          if multplicands.length == 1
            prod = target
          else
            prod = TempMatrix.new op1.rows, op2.cols
          end

          (op1*op2).into_two(prod)
          if op1.is_a?(TempMatrix)
            op1.free
          end
          op1, op2 = prod, multiplicands.shift
        end

      end


    end

    
    def into_two target
      unless target.rows == a.rows && target.cols == b.cols
        raise DimensionError, "incompatible matrix dimensions"
      end
      raise unless length == 2
      a, b = chain

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
