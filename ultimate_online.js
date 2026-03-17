(function () {
    'use strict';

    function start() {

        console.log('ULTIMATE START OK');

        Lampa.Component.add('ultimate_online', {

            init: function () {
                this.activity.loader(false);
                this.render();
            },

            render: function () {
                this.empty();

                this.append(
                    '<div style="padding:20px">' +
                    '<h1>Ultimate работает</h1>' +
                    '<button id="btn">Проверка</button>' +
                    '</div>'
                );

                setTimeout(function () {
                    var btn = document.getElementById('btn');
                    if (btn) {
                        btn.onclick = function () {
                            alert('ВСЁ РАБОТАЕТ 💀');
                        };
                    }
                }, 500);
            }
        });

        Lampa.Menu.add({
            title: 'Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    // 💣 ВАЖНО: двойной запуск
    if (window.appready) start();
    window.addEventListener('appready', start);

})();
