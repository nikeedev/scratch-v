module main

import net.websocket
import term
import time
import json
import os

// https://turbowarp.org/777954330

struct Data {
    user       string
    project_id int
}

struct Handshake {
	user       string
    project_id int
    method     string = 'handshake'
}

struct Message {
    user       string
    project_id int
    method     string
    name       string
    value      f64
}

fn create_handshake(data Data) Handshake {
    return Handshake{data.user, data.project_id, 'handshake'}
}

fn create_message(var_action string, var_name string, var_value f64, data Data) Message {
    return Message{data.user, data.project_id, var_action, var_name, var_value}
}

// Handshake: { "method": "handshake", "user": "nikeedev", "project_id": project_id }

// Message: { "method": "set", "user": "nikeedev", "project_id": project_id, "name": "☁ cloud", "value": input_data.value }

fn main() {
	println(term.magenta('Link to project: https://turbowarp.org/777954330'))
	data := Data{'nikeedev', 777954330}

	// println(json.encode(create_handshake(data)))
	// println(json.encode(create_message('set', '☁ cloud', num, data)))

	mut ws := start_client()!

	println(term.green('client ${ws.id} ready'))

	println(json.encode(create_handshake(data)))
	println('')

	ws.write_string(json.encode(create_handshake(data)))!
	time.sleep(1000)
	println('Handshake completed')

	for {
		println('Write a number to send to ${data.project_id}...')
		mut num := os.get_line()
		if num == '' {
			break
		}
		ws.write_string(json.encode(create_message('set', '☁ cloud', num.f64(), data)))!
		println('Message "${num}" sent to server')
	}

	ws.close(1000, 'normal') or { println(term.red('panicing ${err}')) }
	unsafe {
		ws.free()
	}
}

fn start_client() !&websocket.Client {
	mut ws := websocket.new_client('wss://clouddata.turbowarp.org/')!

	ws.header.add_custom('User-Agent', 'scratch-v/0.1.0 scratch.mit.edu/users/nikeedev')!
	ws.header.add_custom('Host', 'clouddata.turbowarp.org')!
	ws.header.add_custom('Origin', 'https://turbowarp.org')!

	ws.on_open(fn (mut ws websocket.Client) ! {
		println(term.green('websocket connected to the turbowarp server and ready to send messages...'))
	})

	// use on_error_ref if you want to send any reference object
	ws.on_error(fn (mut ws websocket.Client, err string) ! {
		println(term.red('error: ${err}'))
	})

	// use on_close_ref if you want to send any reference object
	ws.on_close(fn (mut ws websocket.Client, code int, reason string) ! {
		println(term.green('the connection to the server successfully closed'))
	})

	// on new messages from other clients, display them in blue text
	ws.on_message(fn (mut ws websocket.Client, msg &websocket.Message) ! {
		if msg.payload.len > 0 {
			message := msg.payload.bytestr()
			println(term.blue('Message recieved: ${json.decode(Message, message)}'))
		}
	})

	ws.connect() or {
		eprintln(term.red('ws.connect error: ${err}'))
		return err
	}

	spawn ws.listen() // or { println(term.red('error on listen $err')) }
	return ws
}
