require "Sketchup.rb"

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

module DKS
    # returns a list of all the Groups and ComponentInstances that do not include
    # any sub-groups or sub-components
    def self.get_members(entity,visible_only)

        members = Array.new
        has_subgroups = false

        entity.entities.select{|e| (e.is_a?(Sketchup::Group) or \
                               e.is_a?(Sketchup::ComponentInstance)) and \
                               (e.visible? or !visible_only ) and 
                               (e.layer.visible? or !visible_only ) \
                              }.each { |e|
            members.concat( get_members( e, visible_only ) )
            has_subgroups = true
        }

        if not has_subgroups and \
           (entity.visible? or !visible_only) and \
           (entity.layer.visible? or !visible_only) then
            members.push( entity )
        end
    
        members
    end

    def self.reset_member_colours(model=Sketchup.active_model, colour="white")
        set_colour(get_members(model,false),colour)
    end

    #utility function to reset the color of the whole model
    def self.set_colour(entities, colour="white")
        entities.each do |m|
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

        def reset_count()
            @count = 0
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

        def reset_count()
            @count = 0
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

    @@sizes = [LumberSize.new("2x2", 1.5.to_l, 1.5.to_l, 0.1.to_l, "pink"), 
        LumberSize.new("1x4", 0.75.to_l,3.5.to_l,0.1.to_l, "blue"),
        LumberSize.new("1x2", 0.75.to_l, 1.5.to_l, 0.1.to_l,"purple"),
        LumberSize.new("1x3", 0.75.to_l, 2.5.to_l, 0.1.to_l,"red"),
        LumberSize.new("1x10", 0.75.to_l, 9.5.to_l, 0.1.to_l, "yellow"),
        LumberSize.new("2x3", 1.5.to_l,2.5.to_l,0.1.to_l, "orange"),
        LumberSize.new("2x4", 1.5.to_l, 3.5.to_l, 0.2.to_l, "gray"),
        LumberSize.new("2x6", 1.5.to_l, 5.5.to_l, 0.1.to_l, "Brown"),
        PlywoodSize.new("1/2\" sheet", 0.5.to_l, 0.05.to_l, "green"),
        PlywoodSize.new("3/4\" sheet", 0.75.to_l, 0.05.to_l, "LightGreen")]

    def self.colour_members(members)

        @@sizes.each do |m|
            m.reset_count
        end

        members.each do |m|
            bbox = m.local_bounds

            @@sizes.each do |l|
                (matches, length) = l.matches?(bbox.width, bbox.depth, bbox.height)
                if matches then
                    puts "#{l.tag}, length: #{length.to_f.to_mm.round(0)}, Sketchup ID: #{m.entityID}"
                    l.add
                    m.material=(l.colour)
                    break
                end
            end
        end

        @@sizes.each do |l|
            puts "#{l.tag}: #{l.count}"
        end
    
    end


end

unless file_loaded?(__FILE__)
    menu = UI.menu("Extensions")
    menu.add_item("Count and Colour Visible Timber") {DKS::colour_members( DKS::get_members(Sketchup.active_model, true ) )}
    menu.add_item("Count and Colour All Timber") {DKS::colour_members( DKS::get_members(Sketchup.active_model, false ))}
    menu.add_item("Count and Colour Selected") {DKS::colour_members( DKS::get_selected_members(Sketchup.active_model, true))}
    menu.add_item("Reset all groups to white") {DKS::reset_member_colours(Sketchup.active_model)}
    menu.add_item("Reset selected groups to white") {DKS::set_colour(Sketchup.active_model.selection)}
    file_loaded(__FILE__)
end
