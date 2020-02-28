import Logging: AbstractLogger, LogLevel, Info
import Logging: shouldlog, min_enabled_level, catch_exceptions, handle_message
using Dates: DateTime
using TimeZones: now, localzone

struct ContextLogger <: AbstractLogger
    stream::IO
    min_level::LogLevel
    auto_flush::Bool
end

function ContextLogger(stream::IO=stderr, level=Info, auto_flush=false)
    ContextLogger(stream, level, auto_flush)
end

shouldlog(logger::ContextLogger, level, _module, group, id) = true

min_enabled_level(logger::ContextLogger) = logger.min_level

catch_exceptions(logger::ContextLogger) = false

function handle_message(logger::ContextLogger, level, message, _module, group, id,
                        filepath, line; kwargs...)
    buf = IOBuffer()
    iob = IOContext(buf, logger.stream)
    context_data = key_value_string(context().data)
    regular_data = key_value_string(kwargs)
    message_data = escape_quote(message)
    println(iob, now(localzone()),
        # " id=", id,
        # " group=", group,
        " level=", log_level_string(level),
        length(context_data) > 0 ? ", message=" : "",
        message_data,
        length(context_data) > 0 ? ", " : "",
        context_data,
        length(regular_data) > 0 ? ", " : "",
        regular_data)
    write(logger.stream, take!(buf))
    logger.auto_flush && flush(logger.stream)
    return nothing
end

# TODO not very performant
log_level_string(level::LogLevel) = uppercase(string(level))

function escape_quote(v, quotechar = "\"")
    s = string(v)
    if occursin(r"[\s\"]", s)
        noquote_string = replace(s, r"\"" => "\\\"")
        return "$(quotechar)$(noquote_string)$(quotechar)"
    end
    return s
end

function escape_space(v, replacement = "_")
    s = string(v)
    return replace(s, r"\s" => replacement)
end

function key_value_string(pairs, separator = ", ")
    kv_array = [escape_space(pair.first) * "=" * escape_quote(pair.second)
        for pair in pairs]
    join(sort(kv_array), separator)
end
