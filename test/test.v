import net.websocket
import net.http
import term
import time
import json
import os
import zztkm.vdotenv



/// For Authentication

struct User {
mut:
	username  string
	password  string
}

///

// https://scratch.mit.edu/777954330

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
	project_id int
	name   string
	value  f64
}

struct Create {
	method string
	project_id int
	name   string
	value  f64
}

struct Rename {
	method   string
	project_id int
	name     string
	new_name string
}

struct Delete {
	method string
	project_id int
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


struct MyCookie {
mut:
	cookie http.Cookie
}

__global(
	my_cookie = MyCookie{}
)

fn main() {
	vdotenv.load()
	user := User{username: os.getenv("USERNAMEenv"), password: os.getenv("PASSWORDenv")}
	mut conf := http.FetchConfig{
		url: 'https://scratch.mit.edu/login/'
		data: json.encode(user)
		method: .post
	}
	conf.cookies['scratchcsrftoken'] = 'a'

	conf.header.add_custom('X-Requested-With', 'XMLHttpRequest') !
    conf.header.add_custom('X-CSRFToken', 'a') !
	conf.header.add_custom('Referer', 'https://scratch.mit.edu') !
	// conf.header.add_custom('Cookie', 'scratchcsrftoken=a;') !
	conf.header.add_custom('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36') !
	conf.header.add_custom('content_type', 'application/json') !

	mut response := http.fetch(conf) !
	println(response)
	my_cookie.cookie = response.cookies()[0]
	println(my_cookie.cookie.value)

	println(term.magenta('Link to project: https://scratch.mit.edu/projects/${project_id}'))
	data := Data{'nikeedev', project_id}

	// println(json.encode(create_handshake(data)))
	// println(json.encode(create_message('set', '☁ cloud', num, data)))

	mut ws := start_client() !

	println(term.green('client ${ws.id} ready'))

	println(json.encode(create_handshake(data)))
	println('')

	ws.write_string(json.encode(create_handshake(data))) !
	time.sleep(1000)
	println('Handshake completed')


	ws.write_string(json.encode(Set{'set', data.project_id, '☁ cloud', 56}))!
	println('Sat ☁ cloud to 56')


	ws.close(1000, 'normal') or { println(term.red('panicing ${err}')) }
	unsafe {
		ws.free()
	}
}




fn start_client() !&websocket.Client {
	mut ws := websocket.new_client('wss://clouddata.scratch.mit.edu/')!

	ws.header.add_custom('cookie', 'scratchsessionsid=${my_cookie.cookie.value};') !
	ws.header.add_custom('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36') !
	ws.header.add_custom('Origin', 'https://scratch.mit.edu') !

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



