require "Sketchup.rb"

mod = Sketchup.active_model # Open model
ent = mod.entities # All entities in model
sel = mod.selection # Current selection

class Sketchup::ComponentInstance
    def local_bounds
        return self.definition.bounds
    end
end

def set_white(model=Sketchup.active_model)
    get_members(model).each do |m|
        m.material=( "white")
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
    
    def count()
        @count +=1
    end
    
    def matches?(u, v, w) # dims is an array of three numbers
        # check depth, then width
        if u - @depth <= @tolerance then
            if v - @width <= @tolerance then
                return true, w.to_l
            elsif w - @width <= @tolerance then
                return true, v.to_l
            end
        end
        
        if v - @depth <= @tolerance then
            if u - @width <= @tolerance then
                return true, w.to_l
            elsif w - @width <= @tolerance then
                return true, u.to_l
            end
        end
        
        if w - @depth <= @tolerance then
            if v - @width <= @tolerance then
                return true, u.to_l
            elsif u - @width <= @tolerance then
                return true, v.to_l
            end
        end
        
        return false, 0
            
    end
end

def get_members(entity)

    members = Array.new
    has_subgroups = false
    if entity.is_a?(Sketchup::ComponentInstance) then
         sub_entities = entity.definition.entities
    else
         sub_entities = entity.entities
    end
    sub_entities.each { |e|
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

sizes = [LumberSize.new("2x2", 1.5, 1.5, 0.1, "pink"), 
    LumberSize.new("1x4", 0.75,3.5,0.1, "blue"), 
    LumberSize.new("1x10", 0.75, 9.5, 0.1, "yellow"),
    LumberSize.new("2x4", 1.5, 3.5, 0.2, "green")]

get_members( mod ).each do |m|
    sizes.each do |l|
        bbox = m.local_bounds
        (matches, length) = l.matches?(bbox.width.to_f, bbox.depth.to_f, bbox.height.to_f)
        if matches then
            puts "#{l.tag}, #{length}"
            l.count
            m.material=(l.colour)
            break
        end
        m.material=("white")
    end
 end

sizes.each do |l|
    puts "#{l.tag}: #{l.count}"
end
0
