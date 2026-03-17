(function () {
    'use strict';

    function startPlugin() {

        Lampa.Component.add('ultimate_online', {

            init: function () {
                this.render();
            },

            render: function () {
                this.activity.loader(false);
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
                            alert('ПЛАГИН ЖИВОЙ');
                        };
                    }
                }, 300);
            }
        });

        Lampa.Menu.add({
            title: 'Ultimate',
            component: 'ultimate_online',
            icon: 'movie'
        });
    }

    if (window.Lampa) startPlugin();
    else window.addEventListener('lampa:ready', startPlugin);

})();
