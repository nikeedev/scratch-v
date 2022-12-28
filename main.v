module main

import net.websocket
import term
import time
import json


// https://turbowarp.org/777954330

struct Data {
	user    string
	project_id int
}

struct Handshake {
	method string
	user string
	project_id int
}

struct Message {
	method string
	user string
	project_id int
	name string
	value int
}

fn create_handshake(data Data) Handshake {
	return Handshake{
		"handshake",
		data.user,
		data.project_id
	}
}

fn create_message(var_action string, var_name string, var_value int, data Data) Message {
	return Message{
		var_action
		data.user,
		data.project_id,
		var_name,
		var_value
	}
}

// Handshake: { "method": "handshake", "user": "nikeedev", "project_id": project_id }

// Message: { "method": "set", "user": "nikeedev", "project_id": project_id, "name": "☁ cloud", "value": input_data.value }

fn main() {
	println('Link to project: https://turbowarp.org/777954330')
	data := Data{'nikeedev', 777954330}

	println(json.encode(create_handshake(data)))
	println(json.encode(create_message('set', '☁ cloud', 7, data)))


	mut ws := start_client()!

	println(term.green('client ${ws.id} ready'))

	ws.write_string(json.encode(create_handshake(data)))!
	time.sleep(1000)
	println("Handshake completed")
	ws.write_string(json.encode(create_message('set', '☁ cloud', 7, data)))!
	println('Message sent to server')

	ws.close(1000, 'normal') or { println(term.red('panicing ${err}')) }
	unsafe {
		ws.free()
	}

}


fn start_client() !&websocket.Client {
	mut ws := websocket.new_client('wss://clouddata.turbowarp.org/')!

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
			println(term.blue('Message recieved: ${message}'))
		}
	})

	ws.connect() or { println(term.red('error on connect: ${err}')) }

	spawn ws.listen() // or { println(term.red('error on listen $err')) }
	return ws
}

