(function () {
    'use strict';

    const TMDB_KEY = 'fdaf4a74e9d8c258e7410d6c7884d872';

    const KP_API_KEY = 'f7cb3415-3901-4f31-9813-991a56c1d683';

    const KP_CACHE = {};

    const VIDEOCDN = {
        tokens: [
            "IAF0wWTdNYZm"
        ],
        domains: [
            "svetacdn.in",
            "annacdn.cc"
        ],
        subs: [
            "4425413"
        ]
    };

    function buildVideoCDN(kp) {
        let urls = [];

        VIDEOCDN.tokens.forEach(token => {
            VIDEOCDN.domains.forEach(domain => {
                VIDEOCDN.subs.forEach(sub => {
                    urls.push(`https://${sub}.${domain}/${token}/movie/${kp}?load=1`);
                });
            });
        });

        return urls;
    }

    async function getKP(imdb) {
        if (KP_CACHE[imdb]) return KP_CACHE[imdb];

        try {
            let res = await fetch(`https://kinopoiskapiunofficial.tech/api/v2.2/films?imdbId=${imdb}`, {
                headers: {
                    'X-API-KEY': KP_API_KEY
                }
            });

            let data = await res.json();

            if (data.items && data.items.length) {
                KP_CACHE[imdb] = data.items[0].kinopoiskId;
                return KP_CACHE[imdb];
            }

            return null;
        } catch (e) {
            console.log('KP error', e);
            return null;
        }
    }

    async function getIds(tmdbId) {
        let res = await fetch(`https://api.themoviedb.org/3/movie/${tmdbId}/external_ids?api_key=${TMDB_KEY}`);
        let data = await res.json();

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

            loadMovies: function () {
                fetch(`https://api.themoviedb.org/3/movie/popular?api_key=${TMDB_KEY}&language=ru-RU`)
                    .then(res => res.json())
                    .then(data => {
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
                    });
            },

            playMovie: async function (movie) {
                console.log("🎬", movie.title);

                let ids = await getIds(movie.id);

                console.log("IDs:", ids);

                if (!ids.kp) {
                    alert("❌ KP ID не найден");
                    return;
                }

                let urls = buildVideoCDN(ids.kp);

                for (let url of urls) {
                    console.log("Пробуем:", url);

                    try {
                        Lampa.Player.play({
                            url: url,
                            title: movie.title
                        });

                        return;
                    } catch (e) {}
                }

                alert("❌ Источник не найден");
            }
        });

        Lampa.Menu.add({
            title: '🔥 Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    if (window.Lampa) startPlugin();
    else window.addEventListener('lampa:ready', startPlugin);
})();
