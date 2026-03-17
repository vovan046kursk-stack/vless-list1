(function () {
    'use strict';

    const TMDB_KEY = 'fdaf4a74e9d8c258e7410d6c7884d872';
    const KP_API_KEY = 'f7cb3415-3901-4f31-9813-991a56c1d683';

    const KP_CACHE = {};

    async function safeFetch(url, options = {}) {
        try {
            let res = await fetch(url, options);
            return await res.json();
        } catch (e) {
            console.log("Fetch error:", url);
            return null;
        }
    }

    async function getKP(imdb) {
        if (!imdb) return null;
        if (KP_CACHE[imdb]) return KP_CACHE[imdb];

        let data = await safeFetch(
            `https://kinopoiskapiunofficial.tech/api/v2.2/films?imdbId=${imdb}`,
            {
                headers: {
                    'X-API-KEY': KP_API_KEY
                }
            }
        );

        if (data && data.items && data.items.length) {
            KP_CACHE[imdb] = data.items[0].kinopoiskId;
            return KP_CACHE[imdb];
        }

        return null;
    }

    async function getIds(tmdbId) {
        let data = await safeFetch(
            `https://api.themoviedb.org/3/movie/${tmdbId}/external_ids?api_key=${TMDB_KEY}`
        );

        if (!data) return {};

        let imdb = data.imdb_id;
        let kp = await getKP(imdb);

        return { imdb, kp };
    }

    function startPlugin() {

        Lampa.Component.add('ultimate_online', {
            template: '<div></div>',

            init: function () {
                this.create();
            },

            create: function () {
                this.render('<div style="padding:20px"><h1>🔥 Ultimate Online</h1><div id="movies"></div></div>');
                this.loadMovies();
            },

            loadMovies: async function () {
                let data = await safeFetch(
                    `https://api.themoviedb.org/3/movie/popular?api_key=${TMDB_KEY}&language=ru-RU`
                );

                if (!data || !data.results) {
                    this.render('<h2 style="padding:20px">❌ TMDB не отвечает</h2>');
                    return;
                }

                let container = document.getElementById('movies');

                data.results.forEach(movie => {
                    let item = document.createElement('div');

                    item.innerHTML = `
                        <div style="margin-bottom:15px; cursor:pointer;">
                            <img src="https://image.tmdb.org/t/p/w200${movie.poster_path}">
                            <p>${movie.title}</p>
                        </div>
                    `;

                    item.onclick = () => this.playMovie(movie);

                    container.appendChild(item);
                });
            },

            playMovie: async function (movie) {
                let ids = await getIds(movie.id);

                if (!ids.kp) {
                    alert("❌ KP не найден");
                    return;
                }

                let url = `https://4425413.svetacdn.in/IAF0wWTdNYZm/movie/${ids.kp}?load=1`;

                Lampa.Player.play({
                    url: url,
                    title: movie.title
                });
            }
        });

        Lampa.Menu.add({
            title: '🔥 Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    try {
        if (window.Lampa) startPlugin();
        else window.addEventListener('lampa:ready', startPlugin);
    } catch (e) {
        console.log("Plugin crash prevented");
    }

})();
