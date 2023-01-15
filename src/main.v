module main

import net.websocket
import term
import time
import json
import os

// https://turbowarp.org/777954330

const project_id = 777954330

struct Data {
	user       string
	project_id int
}

struct Handshake {
	user       string
	project_id int
	method     string = 'handshake'
}

struct Set {
	method string
	name   string
	value  f64
}

struct Create {
	method string
	name   string
	value  f64
}

struct Rename {
	method   string
	name     string
	new_name string
}

struct Delete {
	method string
	name   string
}

fn create_handshake(data Data) Handshake {
	return Handshake{
		user: data.user
		project_id: data.project_id
	}
}

// Handshake: { "method": "handshake", "user": "nikeedev", "project_id": project_id }

// Message: { "method": "set", "name": "☁ cloud", "value": input_data.value }

fn main() {
	println(term.magenta('Link to project: https://turbowarp.org/${project_id}'))
	data := Data{'nikeedev', project_id}

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
		mut num := f64(0)
		mut name := ''

		print('Name of the variable thats getting affected: ')
		mut var_name := '☁ ' + os.get_line().str()
		println('')

		print('Task to do to ${var_name} (set, create, rename, or delete): ')
		mut task := os.get_line().str().trim_space().to_lower()
		println('')

		if task == 'set' || task == 'create' {
			print('What number to set on ${var_name}? ')
			num = os.get_line().f64()
		}

		else if task == 'rename' {
			print('What name to set on ${var_name}? ')
			name = os.get_line().str()
			if name == '' {
				name = var_name
			}
			else {
				continue
			}
		}

		match task {
			'set' {
				ws.write_string(json.encode(Set{'set', var_name, num}))!
				println('Sat ${var_name} to ${num}')
			}
			'create' {
				ws.write_string(json.encode(Create{'create', var_name, num}))!
				println('Created variable ${var_name} with value ${num}')
			}
			'rename' {
				ws.write_string(json.encode(Rename{'rename', var_name, name}))!
				println('Renamed ${var_name} to ${num}')
			}
			'delete' {
				print('Are you sure you want to delete the $var_name variable? ')
				mut sure := os.get_line().str().trim_space().to_lower()
				if sure == 'yes' || sure == 'y' {
					ws.write_string(json.encode(Delete{'delete', var_name}))!
					println('Deleted ${var_name}')
				}
				else {
					continue
				}
			}
			else {
				continue
			}
		}
		name = ""
		var_name = ""
		num = 0
	}

	ws.close(1000, 'normal') or { println(term.red('panicing ${err}')) }
	unsafe {
		ws.free()
	}
}

fn start_client() !&websocket.Client {
	mut ws := websocket.new_client('wss://clouddata.turbowarp.org/')!

	ws.header.add_custom('User-Agent', 'scratch-v/0.1.0 scratch.mit.edu/users/nikeedev')!

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
			println(term.blue('Message recieved: ${json.decode(Set, message)}'))
		}
	})

	ws.connect() or {
		eprintln(term.red('ws.connect error: ${err}'))
		return err
	}

	spawn ws.listen() // or { println(term.red('error on listen $err')) }
	return ws
}
