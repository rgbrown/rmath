module RMath
  class DimensionError < StandardError
  end
  class NotSizedError < StandardError
  end

  module Expression
    def * rhs
      ProductChain.new [self, rhs]
    end

    def + rhs
      AdditionChain.new [self, rhs]
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
    attr_writer :rows, :cols

  
    def initialize name, rows=nil, cols=nil
      @name = name
      @rows = rows
      @cols = cols
    end
  
    def unsized?
      !(@rows && @cols)
    end

    def init
      declaration + "\n" + malloc
    end

    def rows
      @rows || raise(NotSizedError, "No rows defined on #{inspect}")
    end

    def cols
      @cols || raise(NotSizedError, "No cols defined on #{inspect}")
    end

    def allocated?
      !!@allocated
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

    private

    def declaration
      "double *#{name};"
    end

    def malloc
      @allocated = true
      "#{name} = malloc(#{rows * cols} * sizeof (*#{name}));"
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






  class AdditionChain
    include Expression

    attr_reader :chain

    def initialize chain
      @chain = chain
    end

    def + rhs
      case rhs
      when AdditionChain
        AdditionChain.new chain + rhs.chain
      when Expression
        AdditionChain.new chain + [rhs]
      else
        raise TypeError, "can't add with #{rhs.inspect}"
      end
    end

    def rows
      chain.first.rows
    end
    def cols
      chain.first.cols
    end
    def length
      chain.length
    end

    def into target
      code = [] 
      if target.unsized?
        target.rows = rows
        target.cols = cols
        code << target.init
      end
      unless target.rows == rows && target.cols == cols  
        raise DimensionError, "incompatible target matrix dimensions"
      end
      if chain.any?{|x| x.rows != rows || x.cols != cols}
        raise DimensionError, "nonconforming matrix dimensions"
      end

      addends = chain.collect do |expr|
        if expr.is_a? Matrix
          expr
        else
          op = TempMatrix.new expr.rows, expr.cols
          code << op.init
          code << expr.into(op)
          op
        end
      end

      i, j = %w{i j}

      
      code << <<-EOS
for (int i = 0; i < #{rows}; i++) {
    for (int j = 0; j < #{cols}; j++) {
        #{target[i, j]} = #{addends.map{|x| x[i,j]}.join(" + ")};
    }
}
      EOS
      addends.each do |expr|
        if expr.is_a? TempMatrix
          code << expr.free
        end
      end
      code.join "\n"
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
        # Something that isn't a ProductChain but includes Expression
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
      code = []
      if target.unsized?
        target.rows = rows
        target.cols = cols
        code << target.init
      end
      multiplicands = chain.collect do |expr|
        if expr.is_a? Matrix
          expr
        else
          op = TempMatrix.new expr.rows, expr.cols
          code << op.init
          code << expr.into(op)
          op
        end
      end
      mult_original = multiplicands.dup

      if multiplicands.length == 2
        code << into_two(target)
      elsif length <= 1
        raise NotImplementedError
      else
        op1 = multiplicands.shift
        op2 = multiplicands.shift
        loop do
          unless multiplicands.any?
            prod = target
          else
            prod = TempMatrix.new op1.rows, op2.cols
            code << prod.init
          end

          code << (op1*op2).into_two(prod)
          if op1.is_a?(TempMatrix)
            code << op1.free
          end
          break if multiplicands.empty?

          op1, op2 = prod, multiplicands.shift
        end
      end

      mult_original.each do |expr|
        if expr.is_a? TempMatrix
          code << expr.free
        end
      end

      code.join "\n"
    end

    protected

    def into_two target
      raise unless length == 2
      a, b = chain
      unless a.cols == b.rows
        raise DimensionError, "nonconforming matrix dimensions"
      end
      unless target.rows == a.rows && target.cols == b.cols  
        raise DimensionError, "incompatible target matrix dimensions"
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
