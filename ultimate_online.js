(function () {
    'use strict';

    function startPlugin() {

        Lampa.Component.add('simple_online', {
            template: '<div></div>',

            init: function () {
                this.create();
            },

            create: function () {
                this.render(`
                    <div style="padding:20px">
                        <h1>🎬 Онлайн поиск</h1>
                        <input id="search" placeholder="Введите фильм..." style="width:100%;padding:10px;font-size:18px"/>
                        <div id="results"></div>
                    </div>
                `);

                document.getElementById('search').addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') {
                        this.search(e.target.value);
                    }
                });
            },

            search: function (query) {
                let container = document.getElementById('results');
                container.innerHTML = "<p>🔍 Ищем...</p>";

                // ПРОСТО ДЕЛАЕМ iframe через Lumex (или другой источник)
                let url = `https://lumex.space/?search=${encodeURIComponent(query)}`;

                container.innerHTML = `
                    <div style="margin-top:20px;cursor:pointer">
                        <button id="play" style="padding:15px;font-size:18px">▶ Смотреть "${query}"</button>
                    </div>
                `;

                document.getElementById('play').onclick = () => {
                    Lampa.Player.play({
                        url: url,
                        title: query
                    });
                };
            }
        });

        Lampa.Menu.add({
            title: '🎬 Онлайн',
            component: 'simple_online',
            icon: 'search'
        });
    }

    if (window.Lampa) startPlugin();
    else window.addEventListener('lampa:ready', startPlugin);

})();
