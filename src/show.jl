# Display of the generated types, for reading them in the REPL.
#
# The two-argument `show` of the generated code is kept as it is: it prints a value as a
# call to its constructor, which can be evaluated back, and it is what Julia uses inside
# vectors and other containers. Here we add:
#
# - `print` (and so `string` and interpolation) of measurements, such as `VolumeType`, as
#   their value and unit, e.g. "20.0 l";
# - the `text/plain` display, used by the REPL and by `display`, as a tree of the fields
#   that are present, with measurements, ranges and enumerations on a single line.

using .BeerJSONTypes: AbstractSchemaObject, AbstractSchemaEnum

# --- What is a measurement, a range or a named record ---

# measurements have a unit from an enumeration and a value, e.g. `VolumeType`
_ismeasurement(::Type{T}) where {T} =
    T <: AbstractSchemaObject && fieldnames(T) == (:unit, :value) &&
    fieldtype(T, :unit) <: AbstractSchemaEnum
_ismeasurement(x) = _ismeasurement(typeof(x))

# ranges have a minimum and a maximum, both measurements, e.g. `GravityRangeType`
_isrange(x) = x isa AbstractSchemaObject && fieldnames(typeof(x)) == (:minimum, :maximum) &&
    _ismeasurement(x.minimum) && _ismeasurement(x.maximum)

_name(x::AbstractSchemaObject) =
    hasfield(typeof(x), :name) && getfield(x, :name) isa AbstractString ? getfield(x, :name) : nothing

# --- Single-line forms ---

# a number as in compact displays, e.g. 19.0029 for 19.0028767
_compact(io::IO, v) = sprint(show, v; context = IOContext(io, :compact => true))

_measurement(io::IO, x) = string(_compact(io, x.value), " ", x.unit.value)

function _range(io::IO, x)
    lo, hi = x.minimum, x.maximum
    return lo.unit == hi.unit ?
        string(_compact(io, lo.value), " – ", _compact(io, hi.value), " ", lo.unit.value) :
        string(_measurement(io, lo), " – ", _measurement(io, hi))
end

# strings on a single line, shortened when the output is limited (e.g. in the REPL)
function _string(io::IO, s::AbstractString)
    isempty(s) && return "\"\""
    line = first(split(s, '\n'))
    short = get(io, :limit, false) && length(line) > 60
    return short || line != s ? string(first(line, 60), "…") : line
end

# values shown on a single line, or `nothing` for those shown as a subtree
function _inline(io::IO, x)
    x isa AbstractString && return _string(io, x)
    x isa AbstractSchemaEnum && return string(x.value)
    x isa Bool && return string(x)
    x isa Number && return _compact(io, x)
    _ismeasurement(x) && return _measurement(io, x)
    _isrange(x) && return _range(io, x)
    x isa AbstractVector && isempty(x) && return "[]"
    x isa AbstractDict && isempty(x) && return "{}"
    if x isa AbstractVector && !any(v -> v isa Union{AbstractSchemaObject, AbstractVector, AbstractDict}, x)
        return string("[", join((something(_inline(io, v), repr(v)) for v in x), ", "), "]")
    end
    x isa Union{AbstractSchemaObject, AbstractVector, AbstractDict} && return nothing
    return repr(x)
end

# --- The tree ---

# the type, with the numeric types when they are not the default ones
function _typename(T::Type)
    s = string(nameof(T))
    T isa DataType && !isempty(T.parameters) && T.parameters != Core.svec(Int64, Float64) &&
        (s *= string("{", join(T.parameters, ", "), "}"))
    return s
end

# the entries shown below a value: (label, value) pairs
function _entries(x::AbstractSchemaObject)
    named = _name(x) !== nothing
    entries = Pair{String, Any}[]
    for f in fieldnames(typeof(x))
        v = getfield(x, f)
        (v === nothing || (named && f === :name)) && continue
        if f === :_extra
            isempty(v) || push!(entries, "_extra (not in the schema)" => v)
        else
            push!(entries, string(f) => v)
        end
    end
    return entries
end
_entries(x::AbstractDict) = Pair{String, Any}[string(k) => v for (k, v) in x]

const _MAXITEMS = 5       # items of a vector shown when the output is limited

function _entries(io::IO, x::AbstractVector)
    n = length(x)
    shown = get(io, :limit, false) && n > _MAXITEMS + 1 ? _MAXITEMS : n
    entries = Pair{String, Any}["[$i]" => x[i] for i in 1:shown]
    shown < n && push!(entries, "⋮" => _More(n - shown))
    return entries
end
_entries(io::IO, x) = _entries(x)

struct _More
    n::Int
end

# the line of a value shown as a subtree, e.g. "style: Kölsch", "[1] Pilsner",
# "mash_steps (3 items)" or "efficiency:"
function _heading(label, x::AbstractSchemaObject)
    n = _name(x)
    sep = startswith(label, "[") ? " " : ": "
    return n === nothing ? string(label, ":") : string(label, sep, n)
end
_heading(label, x::AbstractVector) = string(label, " (", length(x), length(x) == 1 ? " item)" : " items)")
_heading(label, x::AbstractDict) = string(label, ":")

function _tree(io::IO, x, prefix::String)
    entries = _entries(io, x)
    for (i, (label, v)) in enumerate(entries)
        last = i == length(entries)
        print(io, "\n", prefix, last ? "└─ " : "├─ ")
        if v isa _More
            print(io, v.n, " more")
            continue
        end
        s = _inline(io, v)
        if s === nothing
            print(io, _heading(label, v))
            _tree(io, v, prefix * (last ? "   " : "│  "))
        else
            print(io, label, ": ", s)
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", x::AbstractSchemaObject)
    print(io, _typename(typeof(x)))
    s = _ismeasurement(x) || _isrange(x) ? _inline(io, x) : nothing
    if s !== nothing
        print(io, ": ", s)
    else
        n = _name(x)
        n === nothing || print(io, " ", repr(n))
        _tree(io, x, "")
    end
end

# --- print and string ---

function _printmeasurement(io::IO, x)
    print(io, x.value, " ", x.unit.value)
end

for name in names(BeerJSONTypes)
    T = getfield(BeerJSONTypes, name)
    T isa UnionAll || continue
    D = Base.unwrap_unionall(T)
    D isa DataType && D <: AbstractSchemaObject && _ismeasurement(T{Int64, Float64}) || continue
    @eval Base.print(io::IO, x::$name) = _printmeasurement(io, x)
end
