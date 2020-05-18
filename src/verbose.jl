# Debug logging
const VERBOSE = Ref(false)

"""
    set_verbose!(flag::Bool)

Make it verbose for debugging purpose.
"""
function set_verbose!(flag::Bool)
    VERBOSE[] = flag
end

verbose_log(c::Context, args...) = verbose_log(string(c.id), args...)
verbose_log(id::Integer, args...) = verbose_log(string(id), args...)

const verbose_lock = ReentrantLock()

function verbose_log(label::AbstractString, args...)
    if VERBOSE[]
        try
            lock(verbose_lock)
            println(now(), '\t', label, '\t', args...)
        finally
            unlock(verbose_lock)
        end
    end
end


