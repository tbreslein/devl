build *args:
    zig build {{ args }}

run *args:
    zig build run -- {{ args }}
