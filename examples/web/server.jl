using HTTP
using Sockets
using UUIDs
using ContextLib

# Start a web server that generates a UUID and delegate request to another function
function start_server(host, port)
    socket = Sockets.listen(Sockets.getaddrinfo(host), port)
    task = @async HTTP.listen(; server = socket) do http
        @memo correlation_id = uuid4()
        result = process_request(http)
        write(http, result)
        HTTP.setstatus(http, 200)
        return nothing
    end
    return (task = task, socket = socket)
end

@ctx function process_request()
    context_data = context().data
    return "My correlation_id is " * string(context_data[:correlation_id])
end



function stop_server(server)
    try
        close(server.socket)
        Base.throwto(server.task, InterruptException())
    catch ex
        ex isa InterruptException && return
        rethrow(ex)
    end
end

server = start_server("localhost", 8000)

# Test from the shell prompt
#=
$ curl http://localhost:8000/
OK.  My correlation_id is 73da9213-47e1-4139-8232-7f5c8e43aa08
=#

stop_server(server)
