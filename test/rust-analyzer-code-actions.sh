#!/bin/sh

# REQUIRES: command -v rust-analyzer

. test/lib.sh

cat > .config/kak-lsp/kak-lsp.toml << EOF
[language.rust]
filetypes = ["rust"]
roots = ["Cargo.toml"]
command = "rust-analyzer"
EOF

cat > main.rs << EOF
enum Test {
    Foo,
    Bar,
}
fn main() {
    let foo: Test = Test::Foo;
    match foo {
        Test::Foo => println!("foo"),
        _ => (),
    }
}
EOF

test_tmux_kak_start main.rs

test_tmux send-keys j/foo Enter vtj
test_sleep
test_tmux capture-pane -p | grep 💡
# CHECK: 💡 main.rs 7:11  1 sel - client0@[session]

test_tmux send-keys ,la # lsp-code-actions
test_sleep
test_tmux capture-pane -p | grep -E '\b(Replace|menu)\b'
# CHECK: Replace match with if let{{.*}}
# CHECK: 💡 main.rs 7:11  menu - client0@[session]

test_tmux send-keys Enter
test_sleep
test_tmux capture-pane -p
# CHECK:     let foo: Test = Test::Foo;
# CHECK:     if let Test::Foo = foo {
# CHECK:         println!("foo")
# CHECK:     }
# CHECK: }
# CHECK: ~
# CHECK: 💡 main.rs 7:27 [+] 1 sel - client0@[session]

test_tmux send-keys ,la # lsp-code-actions
test_sleep
test_tmux capture-pane -p | grep Replace
# CHECK: Replace if let with match{{.*}}

test_tmux send-keys Enter
test_sleep
test_tmux capture-pane -p
# CHECK:      let foo: Test = Test::Foo;
# CHECK:      match foo {
# CHECK:          Test::Foo => println!("foo"),
# CHECK:          _ => (),
# CHECK:      }
# CHECK: }
# CHECK: 💡 main.rs 7:14 [+] 1 sel - client0@[session]