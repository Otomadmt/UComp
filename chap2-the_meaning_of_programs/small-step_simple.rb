# def reducible?(expression)
#     case expression
#     when Number
#         false
#     when Add, Multiply
#         true
#     end
# end

# OPERATIONS

class Add < Struct.new(:left, :right)
    def to_s
        "#{left} + #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Add.new(left.reduce(environment), right)
        elsif right.reducible?
            Add.new(left, right.reduce(environment))
        else
            Number.new(left.value + right.value)
        end
    end
end

class Multiply < Struct.new(:left, :right)
    def to_s
        "#{left} * #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            Multiply.new(left.reduce(environment), right)
        elsif right.reducible?
            Multiply.new(left, right.reduce(environment))
        else
            Number.new(left.value * right.value)
        end
    end
end

class LessThan < Struct.new(:left, :right)
    def to_s
        "#{left} < #{right}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if left.reducible?
            LessThan.new(left.reduce(environment), right)
        elsif right.reducible?
            LessThan.new(left, right.reduce(environment))
        else
            Boolean.new(left.value < right.value)
        end
    end
end

# TYPES

class Number < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end
end

class Boolean < Struct.new(:value)
    def to_s
        value.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        false
    end
end

class Variable < Struct.new(:name)
    def to_s
        name.to_s
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        environment[name]
    end
end

# STATEMENTS

class DoNothing
    def to_s
        "literally_doing_nothing"
    end

    def inspect
        "<<#{self}>>"
    end

    def ==(other_statement)
        other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
end

class Assign < Struct.new(:name, :expression)
    def to_s
        "#{name} = #{expression}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        # puts expression
        if expression.reducible?
            [Assign.new(name, expression.reduce(environment)), environment]
        else
            [DoNothing.new, environment.merge({ name => expression })]
        end
    end
end

class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
        "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        if condition.reducible?
            [If.new(condition.reduce(environment), consequence, alternative), environment]
        else
            case condition
            when Boolean.new(true)
                [consequence, environment]
            when Boolean.new(false)
                [alternative, environment]
            end
        end
    end
end

class While < Struct.new(:condition, :body)
    def to_s
        "while (#{condition}) { #{body} }"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
end

class Sequence < Struct.new(:first, :second)
    def to_s
        "#{first}; #{second}"
    end

    def inspect
        "<<#{self}>>"
    end

    def reducible?
        true
    end

    def reduce(environment)
        case first
        when DoNothing.new
            [second, environment]
        else
            reduced_first, reduced_environment = first.reduce(environment)
            [Sequence.new(reduced_first, second), reduced_environment]
        end
    end
end

# INSTANCES

class Machine < Struct.new(:statement, :environment)
    def step
        self.statement, tmp_env = statement.reduce(environment)
        case tmp_env
        when nil
            0
        else
            self.environment = tmp_env
        end
    end

    def run
        while statement.reducible?
            puts "#{statement}, #{environment}"
            step
        end
        puts "#{statement}, #{environment}"
    end
end

# Machine.new(
#     Add.new(
#         Multiply.new(Number.new(9), Number.new(-2)),
#         Add.new(Number.new(5), Number.new(6)),
#         )
#     ).run

# Machine.new(
#     LessThan.new(
#         Multiply.new(Number.new(9), Number.new(-2)),
#         Add.new(Number.new(5), Number.new(6)),
#         )
#     ).run

# Machine.new(
#     Multiply.new(
#         Number.new(1),
#         Multiply.new(
#             Add.new(Number.new(2), Number.new(3)), 
#             Number.new(4)
#             )
#         )
#     ).run

Machine.new(
    Add.new(Variable.new(:x), Variable.new(:y)),
    { x: Number.new(3), y: Number.new(6) }
    ).run

Machine.new(
    If.new(Variable.new(:x),
        Assign.new(:y, Number.new(1)),
        Assign.new(:y, Number.new(2))
        ),
    { x: Boolean.new(true) }
    ).run

Machine.new(
    While.new(
        LessThan.new(Variable.new(:x), Variable.new(:y)),
        Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(2)))
        ),
    { x: Number.new(1), y: Number.new(5) }
    ).run

statement = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
environment = { x: Number.new(2) }
statement, environment = statement.reduce(environment)

# # This machine won't finish
# Machine.new(
#     While.new(
#         LessThan.new(Variable.new(:x), Variable.new(:y)),
#         Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(2)))
#         ),
#     { x: Number.new(-1), y: Number.new(5) }
#     ).run
