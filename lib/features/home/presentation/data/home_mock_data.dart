import 'package:cinmovies_app/features/home/presentation/model/home_movie_model.dart';

const List<MovieCastMember> kMovieCast = [
  MovieCastMember(
    name: 'Marcus Hale',
    character: 'Dr. Nathan Cole',
    photoUrl:
        'https://images.unsplash.com/photo-1587397845856-e6cf49176c70?w=120&h=120&fit=crop&q=80',
  ),
  MovieCastMember(
    name: 'Elena Voss',
    character: 'Agent Sarah Quinn',
    photoUrl:
        'https://images.unsplash.com/photo-1581841064838-a470c740e8ee?w=120&h=120&fit=crop&q=80',
  ),
  MovieCastMember(
    name: 'Claire Monroe',
    character: 'Dr. Leah Winters',
    photoUrl:
        'https://images.unsplash.com/photo-1517462964-21fdcec3f25b?w=120&h=120&fit=crop&q=80',
  ),
  MovieCastMember(
    name: 'Darius Kane',
    character: 'Victor Strand',
    photoUrl:
        'https://images.unsplash.com/photo-1677543167033-af3c688aa4df?w=120&h=120&fit=crop&q=80',
  ),
];

const List<MovieReview> kMovieReviews = [
  MovieReview(
    username: 'filmcritic_leo',
    avatarUrl:
        'https://images.unsplash.com/photo-1587397845856-e6cf49176c70?w=64&h=64&fit=crop&q=80',
    rating: 9,
    text:
        'An absolute standout. The cinematography is rich, the pacing is sharp, and every major scene lands with purpose.',
    date: 'June 12, 2025',
    helpful: 342,
  ),
  MovieReview(
    username: 'cinephile_mara',
    avatarUrl:
        'https://images.unsplash.com/photo-1517462964-21fdcec3f25b?w=64&h=64&fit=crop&q=80',
    rating: 8,
    text:
        'Visually striking and surprisingly emotional. The final act has a twist that makes the whole story click.',
    date: 'June 8, 2025',
    helpful: 198,
    spoiler: true,
  ),
  MovieReview(
    username: 'movie_buff_99',
    avatarUrl:
        'https://images.unsplash.com/photo-1677543167033-af3c688aa4df?w=64&h=64&fit=crop&q=80',
    rating: 7,
    text:
        'Strong performances and a great score. It slows down in the middle, but the ending makes up for it.',
    date: 'May 30, 2025',
    helpful: 87,
  ),
];

const List<HomeMovieModel> kHomeMovies = [
  HomeMovieModel(
    id: 'avengers-doomsday',
    title: 'Avengers: Doomsday',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: ['Action', 'Sci-Fi'],
    rating: 8.7,
    year: '2026',
    duration: '2h 24m',
    ageRating: 'PG-13',
    synopsis:
        'Earth faces a collapsing multiverse when a brilliant tyrant bends time, technology, and fractured alliances toward one final extinction event.',
    director: 'Anthony Russo',
    votes: '186K',
    availability: MovieAvailability.comingSoon,
    cast: kMovieCast,
    reviews: kMovieReviews,
  ),
  HomeMovieModel(
    id: 'spider-man-brand-new-day',
    title: 'Spider-Man: Brand New Day',
    imageAsset: 'assets/images/movie_ex2.jpg',
    genres: ['Adventure', 'Hero'],
    rating: 8.5,
    year: '2026',
    duration: '2h 8m',
    ageRating: 'PG-13',
    synopsis:
        'Peter Parker tries to rebuild a normal life in New York, but a street-level mystery pulls him back into danger before the city is ready for his return.',
    director: 'Destin Daniel Cretton',
    votes: '142K',
    availability: MovieAvailability.comingSoon,
    cast: kMovieCast,
    reviews: kMovieReviews,
  ),
  HomeMovieModel(
    id: 'phantom-horizon',
    title: 'The Phantom Horizon',
    imageAsset: 'assets/images/movie_ex1.jpg',
    genres: ['Sci-Fi', 'Thriller'],
    rating: 8.3,
    year: '2025',
    duration: '2h 18m',
    ageRating: 'PG-13',
    synopsis:
        'A deep-space anomaly starts rewriting physical laws, forcing an astrophysicist to decode ancient signals before reality folds in on itself.',
    director: 'Adrienne Holst',
    votes: '98K',
    availability: MovieAvailability.streaming,
    cast: kMovieCast,
    reviews: kMovieReviews,
  ),
  HomeMovieModel(
    id: 'crimson-protocol',
    title: 'Crimson Protocol',
    imageAsset: 'assets/images/movie_ex2.jpg',
    genres: ['Action', 'Spy'],
    rating: 7.8,
    year: '2025',
    duration: '2h 12m',
    ageRating: 'R',
    synopsis:
        'A black-ops operative discovers her agency has been compromised and goes rogue long enough to expose the truth.',
    director: 'Viktor Slade',
    votes: '74K',
    availability: MovieAvailability.rental,
    cast: kMovieCast,
    reviews: kMovieReviews,
  ),
];
