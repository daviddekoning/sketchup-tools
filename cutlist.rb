require "Sketchup.rb"

module DKS
    mod = Sketchup.active_model # Open model
    ent = mod.entities # All entities in model
    sel = mod.selection # Current selection

    # returns a list of all the Groups and ComponentInstances that do not include
    # any sub-groups or sub-components
    def get_members(entity)

        members = Array.new
        has_subgroups = false

        entity.entities.each { |e|
            if ( e.is_a?(Sketchup::Group) or e.is_a?(Sketchup::ComponentInstance) ) then
                members.concat( get_members( e ) )
                has_subgroups = true
            end
        }

        if not has_subgroups then
            members.push( entity )
        end
    
        return members
    end

    # Extending Sketchup classes to give us the methods and operators to make life easier
    class Sketchup::ComponentInstance
        def local_bounds
            return self.definition.bounds
        end
    
        def entities
            return self.definition.entities
        end
    end

    class Sketchup::Length
        def + (l)
            (self.to_f + l.to_f).to_l
        end
        def - (l)
            (self.to_f - l.to_f).to_l
        end
    end

    #utility function to reset the color of the whole model
    def set_colour(model=Sketchup.active_model, colour="white")
        get_members(model).each do |m|
            m.material=(colour)
        end
    end

    class PlywoodSize
        attr_reader :tag, :count, :colour
    
        def initialize(tag, t, tol, c)
            @tag = tag
            @thickness = t
            @tolerance = tol
            @colour = c
            @count = 0
        end
    
        def add()
            @count +=1
        end
    
        def matches?(u,v,w)
            if (u - @thickness).abs < @tolerance or
               (v - @thickness).abs < @tolerance or
               (w - @thickness).abs < @tolerance then
                return true
            end
            return false
        end
    end

    class LumberSize
        attr_reader :tag, :count, :colour

        def initialize(tag, d, w, tol, c)
            @tag = tag
            @depth = d
            @width = w
            @tolerance = tol
            @colour = c
            @count = 0
        end
    
        def add()
            @count +=1
        end
    
        def matches?(u, v, w) # u,v and w are Sketchup::Length
            # check depth, then width
            if (u - @depth).abs <= @tolerance then
                if (v - @width).abs <= @tolerance then
                    return true, w
                elsif (w - @width).abs <= @tolerance then
                    return true, v
                end
            end
        
            if (v - @depth).abs <= @tolerance then
                if (u - @width).abs <= @tolerance then
                    return true, w
                elsif (w - @width).abs <= @tolerance then
                    return true, u
                end
            end
        
            if (w - @depth).abs <= @tolerance then
                if (v - @width).abs <= @tolerance then
                    return true, u
                elsif (u - @width).abs <= @tolerance then
                    return true, v
                end
            end
        
            return false, 0
            
        end
    end

    class CutMark
        attr_reader :size, :length, :count
    
        def initialize(size, length)
            @size = size
            @length = length
            @count = 0
        end
    end

    sizes = [LumberSize.new("2x2", 1.5.to_l, 1.5.to_l, 0.1.to_l, "pink"), 
        LumberSize.new("1x4", 0.75.to_l,3.5.to_l,0.1.to_l, "blue"),
        LumberSize.new("1x2", 0.75.to_l, 1.5.to_l, 0.1.to_l,"purple"),
        LumberSize.new("1x3", 0.75.to_l, 2.5.to_l, 0.1.to_l,"red"),
        LumberSize.new("1x10", 0.75.to_l, 9.5.to_l, 0.1.to_l, "yellow"),
        LumberSize.new("2x3", 1.5.to_l,2.5.to_l,0.1.to_l, "orange"),
        LumberSize.new("2x4", 1.5.to_l, 3.5.to_l, 0.2.to_l, "gray"),
        LumberSize.new("2x6", 1.5.to_l, 5.5.to_l, 0.1.to_l, "Brown"),
        PlywoodSize.new("1/2\" sheet", 0.5.to_l, 0.05.to_l, "green"),
        PlywoodSize.new("3/4\" sheet", 0.75.to_l, 0.05.to_l, "LightGreen")]

    get_members( mod ).each do |m|
        bbox = m.local_bounds
        sizes.each do |l|
            (matches, length) = l.matches?(bbox.width, bbox.depth, bbox.height)
            if matches then
                puts "#{l.tag}, #{length.to_f.to_mm.round(0)}, #{m.entityID}"
                l.add
                m.material=(l.colour)
                break
            end
        end
     end

    sizes.each do |l|
        puts "#{l.tag}: #{l.count}"
    end
end
