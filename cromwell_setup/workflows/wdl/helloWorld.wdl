# helloWorld.wdl - A single-stage demonstration workflow in WDL

version 1.0

# Task hello
#
# Parameters:
# - name (String): something to say hello to
#
# Results:
# - Emits "hello <name>" to standard output.
task hello {
    input {
      String name
    }
    
    command {
        echo "Hello ${name}!"
    }

    runtime {
        docker: "debian:stable-slim"
    }
    
    output {
        File response = stdout()
    }
}

# Workflow hello_world
#
# Accepts as input an optional "name" parameter and calls the "hello" task.
workflow hello_world {
  input {
    String name = "World"
  }
  
  call hello {
      input:
          name = name
  }
}