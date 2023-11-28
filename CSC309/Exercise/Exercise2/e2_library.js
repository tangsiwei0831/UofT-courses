/* 
 * This code is provided solely for the personal and private use of students 
 * taking the CSC309H course at the University of Toronto. Copying for purposes 
 * other than this use is expressly prohibited. All forms of distribution of 
 * this code, including but not limited to public repositories on GitHub, 
 * GitLab, Bitbucket, or any other online platform, whether as given or with 
 * any changes, are expressly prohibited. 
*/ 

/* E2 Library - JS */

/*-----------------------------------------------------------*/
/* Starter code - DO NOT edit the code below. */
/*-----------------------------------------------------------*/

// global counts
let numberOfBooks = 0; // total number of books
let numberOfPatrons = 0; // total number of patrons

// global arrays
const libraryBooks = [] // Array of books owned by the library (whether they are loaned or not)
const patrons = [] // Array of library patrons.

// Book 'class'
class Book {
	constructor(title, author, genre) {
		this.title = title;
		this.author = author;
		this.genre = genre;
		this.patron = null; // will be the patron objet

		// set book ID
		this.bookId = numberOfBooks;
		numberOfBooks++;
	}

	setLoanTime() {
		// Create a setTimeout that waits 3 seconds before indicating a book is overdue

		const self = this; // keep book in scope of anon function (why? the call-site for 'this' in the anon function is the DOM window)
		setTimeout(function() {
			
			console.log('overdue book!', self.title)
			changeToOverdue(self);

		}, 3000)

	}
}

// Patron constructor
const Patron = function(name) {
	this.name = name;
	this.cardNumber = numberOfPatrons;

	numberOfPatrons++;
}


// Adding these books does not change the DOM - we are simply setting up the 
// book and patron arrays as they appear initially in the DOM.
libraryBooks.push(new Book('Harry Potter', 'J.K. Rowling', 'Fantasy'));
libraryBooks.push(new Book('1984', 'G. Orwell', 'Dystopian Fiction'));
libraryBooks.push(new Book('A Brief History of Time', 'S. Hawking', 'Cosmology'));

patrons.push(new Patron('Jim John'))
patrons.push(new Patron('Kelly Jones'))

// Patron 0 loans book 0
libraryBooks[0].patron = patrons[0]
// Set the overdue timeout
libraryBooks[0].setLoanTime()  // check console to see a log after 3 seconds


/* Select all DOM form elements you'll need. */ 
const bookAddForm = document.querySelector('#bookAddForm');
const bookInfoForm = document.querySelector('#bookInfoForm');
const bookLoanForm = document.querySelector('#bookLoanForm');
const patronAddForm = document.querySelector('#patronAddForm');

/* bookTable element */
const bookTable = document.querySelector('#bookTable')
/* bookInfo element */
const bookInfo = document.querySelector('#bookInfo')
/* Full patrons entries element */
const patronEntries = document.querySelector('#patrons')

/* Event listeners for button submit and button click */

bookAddForm.addEventListener('submit', addNewBookToBookList);
bookLoanForm.addEventListener('submit', loanBookToPatron);
patronAddForm.addEventListener('submit', addNewPatron)
bookInfoForm.addEventListener('submit', getBookInfo);

/* Listen for click patron entries - will have to check if it is a return button in returnBookToLibrary */
patronEntries.addEventListener('click', returnBookToLibrary)

/*-----------------------------------------------------------*/
/* End of starter code - do *not* edit the code above. */
/*-----------------------------------------------------------*/


/** ADD your code to the functions below. DO NOT change the function signatures. **/


/*** Functions that don't edit DOM themselves, but can call DOM functions 
     Use the book and patron arrays appropriately in these functions.
 ***/

// Adds a new book to the global book list and calls addBookToLibraryTable()
function addNewBookToBookList(e) {
	e.preventDefault();

	// Add book book to global array
	let bookName = document.querySelector("#newBookName").value;
	let bookAuthor = document.querySelector("#newBookAuthor").value;
	let bookGenre = document.querySelector("#newBookGenre").value;

	let newbook = new Book(bookName, bookAuthor, bookGenre)

	libraryBooks.push(newbook);


	// Call addBookToLibraryTable properly to add book to the DOM
	addBookToLibraryTable(newbook);
	
}

// Changes book patron information, and calls 
function loanBookToPatron(e) {
	e.preventDefault();

	// Get correct book and patron
	let bookId = document.querySelector("#loanBookId").value;
	let book = libraryBooks[bookId];

	// Add patron to the book's patron property
	let cardNum = document.querySelector("#loanCardNum").value;
	book.patron = patrons[cardNum];

	// Add book to the patron's book table in the DOM by calling addBookToPatronLoans()
	addBookToPatronLoans(book);

	// Start the book loan timer.
	book.setLoanTime();

}

// Changes book patron information and calls removeBookFromPatronTable()
function returnBookToLibrary(e){
	e.preventDefault();
	// check if return button was clicked, otherwise do nothing.

	if(e.target.className == 'return') {
		let row = e.target.parentElement.parentElement;
		let bookId = parseInt(row.children[0].innerText);
		let book = libraryBooks[bookId];

		// Call removeBookFromPatronTable()
		removeBookFromPatronTable(book);

		// Change the book object to have a patron of 'null'
		book.patron = null;
	}


}

// Creates and adds a new patron
function addNewPatron(e) {
	e.preventDefault();
	// Add a new patron to global array
	let name = document.querySelector("#newPatronName").value;
	let newPatron = new Patron(name);
	patrons.push(newPatron);

	// Call addNewPatronEntry() to add patron to the DOM
	addNewPatronEntry(newPatron);

}

// Gets book info and then displays
function getBookInfo(e) {
	e.preventDefault();

	// Get the correct book object.
  	let bookId = document.querySelector("#bookInfoId").value;
	let book = libraryBooks[bookId];

	// Call displayBookInfo()
	displayBookInfo(book);

}


/*-----------------------------------------------------------*/
/*** DOM functions below - use these to create and edit DOM objects ***/

// Adds a book to the library table.
function addBookToLibraryTable(book) {
	// Add code here
	let row = document.createElement('tr');
	let bookId = document.createElement('td');
	let bookTitle = document.createElement('td');
	let patronNum = document.createElement('td');
	let strong = document.createElement('strong');

	strong.innerText = book.title;
	bookTitle.appendChild(strong);

	bookId.innerText = book.bookId;

	row.appendChild(bookId);
	row.appendChild(bookTitle);
	row.appendChild(patronNum);

	bookTable.children[0].appendChild(row);

}


// Displays detailed info on the book in the Book Info Section
function displayBookInfo(book) {
	// Add code here
	bookInfo.children[0].children[0].innerText = book.bookId;
	bookInfo.children[1].children[0].innerText = book.title;
	bookInfo.children[2].children[0].innerText = book.author;
	bookInfo.children[3].children[0].innerText = book.genre;
	if(book.patron){
		bookInfo.children[4].children[0].innerText = book.patron.name
	}else{
		bookInfo.children[4].children[0].innerText = 'N/A'
	}
	
}

// Adds a book to a patron's book list with a status of 'Within due date'. 
// (don't forget to add a 'return' button).
function addBookToPatronLoans(book) {
	// Add code here
	let bookId = document.createElement('td');
	bookId.innerText = book.bookId;

	let bookTitle = document.createElement('td');
	let strong = document.createElement('strong');
	strong.innerText = book.title;
	bookTitle.appendChild(strong);

	let bookStatus = document.createElement('td');
	let span = document.createElement('span');
	span.className = 'green';
	span.innerText = 'Within due date';
	bookStatus.appendChild(span);

	let returnButton = document.createElement('button');
	returnButton.innerText = 'return';
	returnButton.className = 'return';
	let returnCell = document.createElement('td');
	returnCell.appendChild(returnButton);

	let newRow = document.createElement('tr');
	newRow.appendChild(bookId);
	newRow.appendChild(bookTitle);
	newRow.appendChild(bookStatus);
	newRow.appendChild(returnCell);

	let cardNum = document.querySelector("#loanCardNum").value;

	let table = patronEntries.children[cardNum].children[3]
	table.children[0].appendChild(newRow);

	for(let i = 1; i < bookTable.children[0].children.length; i++) {
		if(bookTable.children[0].children[i].children[0].innerText == book.bookId) {
			bookTable.children[0].children[i].children[2].innerText = cardNum;
		}
	}

}

// Adds a new patron with no books in their table to the DOM, including name, card number,
// and blank book list (with only the <th> headers: BookID, Title, Status, and Return).
function addNewPatronEntry(patron) {
	// Add code here
	let newPatron = document.createElement('div');
	newPatron.className = 'patron';

	let nameCell = document.createElement('p');
	let span1 = document.createElement('span');
	span1.className = 'bold';
	span1.innerText = patron.name;
	nameCell.appendChild(document.createTextNode('Name: '));
	nameCell.appendChild(span1);

	let cardNum = document.createElement('p');
	let span2 = document.createElement('span');
	span2.className = 'bold';
	span2.innerText = patron.cardNumber;
	cardNum.appendChild(document.createTextNode('Card Number: '));
	cardNum.appendChild(span2);

	let loanText = document.createElement('h4');
	loanText.innerText = 'Books on loan:'

	let loanTable = document.createElement('table');
	loanTable.className = 'patronsLoanTable';

	let body = document.createElement('tbody');

	let row = document.createElement('tr');

	let bookId = document.createElement('th');
	bookId.innerText = 'BookID';

	let bookTitle = document.createElement('th');
	bookTitle.innerText = 'Title';

	let bookStatus = document.createElement('th');
	bookStatus.innerText = 'Status';

	let bookReturn = document.createElement('th');
	bookReturn.innerText = 'Return';

	row.appendChild(bookId);
	row.appendChild(bookTitle);
	row.appendChild(bookStatus);
	row.appendChild(bookReturn);

	body.appendChild(row);

	loanTable.appendChild(body);

	newPatron.appendChild(nameCell);
	newPatron.appendChild(cardNum);
	newPatron.appendChild(loanText);
	newPatron.appendChild(loanTable);
	
	patronEntries.appendChild(newPatron);
}


// Removes book from patron's book table and remove patron card number from library book table
function removeBookFromPatronTable(book) {
	// Add code here
	let cardNum = book.patron.cardNumber;
	let table = patronEntries.children[cardNum].children[3];

	for(let i = 0; i < table.children[0].children.length; i++){
		let row = table.children[0].children[i];
		if(row.children[0].innerText == book.bookId){
			table.children[0].removeChild(row);
		}
	}

	for(let i = 0; i < bookTable.children[0].children.length; i++) {
		if(bookTable.children[0].children[i].children[0].innerText == book.bookId) {
			bookTable.children[0].children[i].children[2].innerHTML = null;
		}
	}


}

// Set status to red 'Overdue' in the book's patron's book table.
function changeToOverdue(book) {
	// Add code here
	let cardNum = book.patron.cardNumber;
	let table = patronEntries.children[cardNum].children[3];

	for(let i = 0; i < table.children[0].children.length; i++){
		let row = table.children[0].children[i];
		if(row.children[0].innerText == book.bookId){
			row.children[2].children[0].className = 'red';
			row.children[2].children[0].innerText = 'Overdue';
			
		}
	}


}

