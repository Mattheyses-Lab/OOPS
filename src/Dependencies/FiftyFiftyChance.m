function Result = FiftyFiftyChance(behavior)

    switch behavior
        case 'TrueFalse'
            if OneOrZero();Result=true;else;Result=false;end
        case 'OneZero'
            if OneOrZero();Result=1;else;Result=0;end
        case 'PosNeg'
            if OneOrZero();Result=1;else;Result=-1;end            
    end

    function Num = OneOrZero()
        switch randi(2)
            case 1
                Num = true;
            case 2
                Num = false;
        end
    end

end