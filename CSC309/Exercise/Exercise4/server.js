/* 
 * This code is provided solely for the personal and private use of students 
 * taking the CSC309H course at the University of Toronto. Copying for purposes 
 * other than this use is expressly prohibited. All forms of distribution of 
 * this code, including but not limited to public repositories on GitHub, 
 * GitLab, Bitbucket, or any other online platform, whether as given or with 
 * any changes, are expressly prohibited. 
*/  

/* E4 server.js */
'use strict';
const log = console.log;

// Express
const express = require('express')
const app = express();
const bodyParser = require('body-parser')
app.use(bodyParser.json());

// Mongo and Mongoose
const { ObjectID } = require('mongodb')
const { mongoose } = require('./db/mongoose');
const { Restaurant } = require('./models/restaurant')

/* 
   Restaurant API routes below. 
   Note: You may use async-await if you wish, but you will have to modify the functions as needed.
*/

/// Route for adding restaurant, with *no* reservations (an empty array).
/* 
Request body expects:
{
	"name": <restaurant name>
	"description": <restaurant description>
}
Returned JSON should be the database document added.
*/
// POST /restaurants
app.post('/restaurants', (req, res) => {
	// Add code here
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}
	let restaurant = new Restaurant ({
		name:req.body.name,
		description:req.body.description,
		reservations:[]
	})
	restaurant.save().then((rest) => {
		res.send(rest)
	}).catch((error) => {
		res.status(500).send(error)
	})
})


/// Route for getting all restaurant information.
// GET /restaurants
app.get('/restaurants', (req, res) => {
	// Add code here
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}
	Restaurant.find().then((rest) => {
		res.send(rest)
	}).catch((error) => {
		res.status(500).send(error)
	})
})


/// Route for getting information for one restaurant.
// GET /restaurants/<id>
app.get('/restaurants/:id', (req, res) => {
	// Add code here
	const id = req.params.id

	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}

	if(!ObjectID.isValid(id)){
		res.status(404).send('Restaurant not found')
		return;
	}

	Restaurant.findById(id).then((restaurant) => {
		res.send(restaurant)
	}).catch((error) => {
		res.status(500).send(error)
	})

})


/// Route for adding reservation to a particular restaurant.
/* 
Request body expects:
{
	"time": <time>
	"people": <number of people>
}
*/
// Returned JSON should have the updated restaurant database 
//   document that the reservation was added to, AND the reservation subdocument:
//   { "reservation": <reservation subdocument>, "restaurant": <entire restaurant document>}
// POST /restaurants/<id>
app.post('/restaurants/:id', (req, res) => {
	// Add code here
	const id = req.params.id
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}

	if(!ObjectID.isValid(id)){
		res.status(404).send('Restaurant not found')
		return;
	}

	Restaurant.findById(id).then((rest) => {
		rest.reservations.push(req.body)
		rest.save().then((rest) => {
			res.send({reservation: rest.reservations, restaurant: rest})
		}).catch((error) => {
			res.status(500).send(error)
		})
	}).catch((error) => {
		res.status(500).send(error)
	})
})


/// Route for getting information for one reservation of a restaurant (subdocument)
// GET /restaurants/<restaurant_id>/<reservation_id>
app.get('/restaurants/:id/:resv_id', (req, res) => {
	// Add code here
	const id = req.params.id
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}

	Restaurant.findById(id).then((rest) => {
		let reservation = rest.reservations.id(req.params.resv_id)
		res.send(reservation)
	}).catch((error) => {
		res.status(500).send(error)
	})

})


/// Route for deleting reservation
// Returned JSON should have the updated restaurant database
//   document from which the reservation was deleted, AND the reservation subdocument deleted:
//   { "reservation": <reservation subdocument>, "restaurant": <entire restaurant document>}
// DELETE restaurant/<restaurant_id>/<reservation_id>
app.delete('/restaurants/:id/:resv_id', (req, res) => {
	// Add code here
	const id = req.params.id
	const resvID = req.params.resv_id
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}
	if(!ObjectID.isValid(id)){
		res.status(404).send('Resource not found')
		return;
	}

	if(!ObjectID.isValid(resvID)){
		res.status(404).send('Resource not found')
		return;
	}

	Restaurant.findById(id).then((rest) => {
		let removed = rest.reservations.id(resvID)
		rest.reservations.remove(resvID)
		rest.save().then((rest) => {
			res.send({reservation: removed, restaurant: rest})
		}).catch((error) => {
			res.status(500).send(error)
		})
	}).catch((error) => {
		res.status(500).send(error)
	})

})


/// Route for changing reservation information
/* 
Request body expects:
{
	"time": <time>
	"people": <number of people>
}
*/
// Returned JSON should have the updated restaurant database
//   document in which the reservation was changed, AND the reservation subdocument changed:
//   { "reservation": <reservation subdocument>, "restaurant": <entire restaurant document>}
// PATCH restaurant/<restaurant_id>/<reservation_id>
app.patch('/restaurants/:id/:resv_id', (req, res) => {
	// Add code here
	const id = req.params.id
	const resvID = req.params.resv_id
	if(mongoose.connection.readyState != 1){
		log('Issue with mongoose connection')
		res.status(500).send('Internal server error')
		return;
	}

	if(!ObjectID.isValid(id)){
		res.status(404).send('Resource not found')
		return;
	}

	if(!ObjectID.isValid(resvID)){
		res.status(404).send('Resource not found')
		return;
	}

	Restaurant.findById(id).then((rest) => {
		let resv = rest.reservations.id(resvID)
		resv.time = req.body.time
		resv.people = req.body.people
		rest.save().then((restaurant) => {
			res.send({reservation: resv, restaurant: restaurant})
		}).catch((error) => {
			res.status(500).send(error)
		})
	}).catch((error) => {
		res.status(500).send(error)
	})

})


////////// DO NOT CHANGE THE CODE OR PORT NUMBER BELOW
const port = process.env.PORT || 5001
app.listen(port, () => {
	log(`Listening on port ${port}...`)
});