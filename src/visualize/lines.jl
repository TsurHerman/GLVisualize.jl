visualize_default{T <: Real, N}(::Union{Texture{Point{N, T}, 1}, Vector{Point{N, T}}}, s::Style{:lines}, kw_args=Dict()) = Dict(
    :shape               => RECTANGLE,
    :style               => FILLED,
    :transparent_picking => false,
    :preferred_camera    => :orthographic_pixel,
    :color               => default(RGBA, s),
    :thickness           => 2f0,
    :dotted              => false
)

function visualize{N}(locations::Signal{Vector{Point{N, Float32}}}, s::Style{:lines}, customizations=visualize_default(locations.value,s))
    ll = const_lift(lastlen, locations)
    maxlength = const_lift(last, ll)

    start_valp = GLBuffer(locations.value)
    start_vall = GLBuffer(ll.value)
    const_lift(update!, start_valp, locations)
    const_lift(update!, start_vall, ll)
    visualize(start_valp, start_vall, maxlength, s, customizations)
end

function lastlen(points)
    result = zeros(eltype(points[1]), length(points))
    for i=1:length(points)
        i0 = max(i-1,1)
        result[i] = result[i0] + norm(points[i0]-points[i])
    end
    result
end
function visualize{T <: Point, FT <: AbstractFloat}(positions::GLBuffer{T}, ll::GLBuffer{FT}, maxlength, s::Style{:lines}, data=visualize_default(positions,s))
    ps = gpu_data(positions)
    data[:vertex]    = positions
    data[:lastlen]   = ll
    data[:maxlength] = maxlength
    data[:max_primitives] = Cint(length(positions)-4)

    program = GLVisualizeShader("util.vert", "lines.vert", "lines.geom", "lines.frag", attributes=data)
    std_renderobject(
        data, program,
        Input(AABB{Float32}(ps)), GL_LINE_STRIP_ADJACENCY 
    )
end


function visualize{T <: AbstractFloat}(positions::Vector{T}, range::Range, s::Style{:lines}, data=visualize_default(positions,s))
    length(positions) != length(range) && throw(
        DimensionMismatsch("length of $(typeof(positions)) $(length(positions)) and $(typeof(range)) $(length(range)) must match")
    )
    visualize(points2f0(positions, range), s, data)
end