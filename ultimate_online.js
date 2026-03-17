(function () {
    'use strict';

    function startPlugin() {

        console.log('ULTIMATE PLUGIN LOADED');

        Lampa.Component.add('ultimate_online', {
            name: 'Ultimate',

            init: function () {
                this.render();
            },

            render: function () {
                this.activity.loader(false);

                this.empty();

                this.append(`
                    <div style="padding:20px">
                        <h1>🔥 Ultimate работает</h1>
                        <button id="btn">Проверка</button>
                    </div>
                `);

                setTimeout(() => {
                    let btn = document.getElementById('btn');
                    if (btn) {
                        btn.onclick = () => {
                            alert('ПЛАГИН ЖИВОЙ 💀');
                        };
                    }
                }, 300);
            },

            destroy: function () {
                console.log('destroy');
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
