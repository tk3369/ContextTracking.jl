using Dates: DateTime
using TimeZones: now, localzone
using Logging

# Special labels in the log
const CONTEXT_PATH_KEY = Symbol(".ContextPath")
const CONTEXT_ID_LABEL = Symbol(".ContextId")

Base.@kwdef struct ContextLogger <: AbstractLogger
    stream::IO = stdout
    min_level::LogLevel = Logging.Info
    auto_flush::Bool = false
    include_context_path::Bool = false
    include_context_id::Bool = false
    field_separator::String = " "
end

# Logging extensions

Logging.shouldlog(logger::ContextLogger, level, _module, group, id) = true

Logging.min_enabled_level(logger::ContextLogger) = logger.min_level

Logging.catch_exceptions(logger::ContextLogger) = false

# try to avoid locking issue....?
const splock = ReentrantLock() # Base.Threads.SpinLock()

function Logging.handle_message(logger::ContextLogger,
            level, message, _module, group, id, filepath, line; kwargs...)
    try
        lock(splock)
        buf = IOBuffer()
        iob = IOContext(buf, logger.stream)
        sep = logger.field_separator
        ctx = context()
        context_data = key_value_string(ctx.data,
                            separator = sep,
                            include_context_path = logger.include_context_path)
        regular_data = key_value_string(kwargs,
                            separator = sep)
        message_data = format_value(message)
        println(iob,
            now(localzone()),
            " level=", log_level_string(level),
            "$(sep)message=", message_data,
            logger.include_context_id ? "$(sep)$(CONTEXT_ID_LABEL)=$(ctx.hex_id)" : "",
            length(context_data) > 0 ? "$(sep)" : "", context_data,
            length(regular_data) > 0 ? "$(sep)" : "", regular_data)
        write(logger.stream, take!(buf))
        logger.auto_flush && flush(logger.stream)
        return nothing
    finally
        unlock(splock)
    end
end

# Formatting

log_level_string(level::LogLevel) = uppercase(string(level))

format_value(path::AbstractVector{Symbol}) = join(path, ".")

function format_value(v, quotechar = "\"")
    s = string(v)
    if occursin(r"[\s\"]", s)
        noquote_string = replace(s, r"\"" => "\\\"")
        return "$(quotechar)$(noquote_string)$(quotechar)"
    end
    return s
end

function format_key(v, replacement = "_")
    s = string(v)
    return replace(s, r"\s" => replacement)
end

function key_value_string(pairs; separator = ",", include_context_path = true)
    kv_array = [format_key(pair.first) * "=" * format_value(pair.second)
        for pair in pairs
        if (pair.first === CONTEXT_PATH_KEY && include_context_path) ||
            pair.first !== CONTEXT_PATH_KEY]
    join(sort(kv_array), separator)
end
