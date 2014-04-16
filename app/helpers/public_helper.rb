module PublicHelper
    
    def color?
        if $globalVariable
            return $true
        end
    end
    
    def color
        $globalVariable
    end
end
