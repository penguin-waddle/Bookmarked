# Bookmarked

## Introduction

Bookmarked is an innovative iOS app designed for avid readers. It leverages the Google Books API to provide a comprehensive book searching, reviewing, and tracking experience. While still in development, the app currently features functionalities like book searching, user reviews, book favoriting, and an engaging activity feed.

This project showcases my iOS development skills and commitment to creating feature-rich, user-centric applications.

## Preview
<p float="left">
  <img src="https://github.com/penguin-waddle/Bookmarked/assets/123434744/5b678124-0b43-4bbe-b3cc-86b329a9d2f4) width="400" /> 
  <img src="https://github.com/penguin-waddle/Bookmarked/assets/reviewing_a_book.gif](https://github.com/penguin-waddle/Bookmarked/assets/123434744/b4baf51c-49c7-4337-8e65-fb0433198d28" width="300" /> 
</p> 

<div>
  <p>
    Here's a quick look at <strong>Bookmarked</strong> in action. The first GIF shows the process of logging in, searching for a book, and favoriting it. The second GIF showcases how users can leave reviews for books they've read. 
  </p>
</div>


## Features

* __Book Search:__ Utilize the Google Books API to search for books by title, author, or ISBN.
* __Review System:__ Allows users to write and read reviews, offering insights and opinions on various books.
* __Favorite Books:__ Users can mark books as favorites, making them easily accessible.
* __Activity Feed:__ Displays recent activities from users, including reviews and favorite additions.

## Unique Challenges

### Dynamic Data Fetching in BookDetailView
One of the more intricate challenges in developing Bookmarked was managing the data source for the __'BookDetailView'.__ This view can be accessed from two different points: __'BookSearchView'__ and __'ListView'__ (which includes the activity feed). Each point required a distinct approach to data retrieval:

* __From BookSearchView:__ When accessed through the __'BookSearchView'__, __'BookDetailView'__ fetches book details directly from the Google Books API. This involves handling live API data and presenting it in a detailed format, ensuring that the most current information is displayed.
* __From ListView/Activity Feed:__ Alternatively, when accessed through the __'ListView'__, the data for __'BookDetailView'__ comes from the Firestore database. This scenario involves retrieving stored data, which includes user-generated content like reviews and favorites.
The challenge was to seamlessly integrate these two data sources into __'BookDetailView'__ without duplicating code or compromising the user experience. This required implementing a flexible data handling system that could adapt based on the view's point of entry, ensuring efficient and accurate data presentation.

This challenge was a valuable opportunity to enhance my skills in API integration, database management, and SwiftUI view lifecycle, contributing to my growth as an iOS developer.

## Technologies Used

* __Swift & SwiftUI:__ For crafting native iOS app interfaces.
* __Firebase:__ Utilized for backend operations like user authentication, database management, and storage solutions.
* __Google Books API:__ Integrated to fetch detailed book information and enable book searches.

## Installation

_Note: The app is not yet available on the App Store and requires an API key for full functionality._

To test Bookmarked, clone the repository and open it in Xcode. You'll need to configure it with your own Firebase and Google Books API credentials.

``` 
git clone https://github.com/penguin-waddle/Bookmarked.git
```

## Future Enhancements

* __User Profiles:__ To allow personalization and user-specific content.
* __User Search Functionality:__ To search and follow other users, fostering a community of book lovers.
* __Discovery Page:__ For exploring new books and trending titles, enhancing the user's book-finding experience.

## Contributing

Currently, Bookmarked is a personal project and not open for external contributions. However, feedback and suggestions are highly appreciated. Feel free to reach out with your ideas.

## Contact

For inquiries or feedback regarding Bookmarked, please email vivienwuquach@gmail.com.
