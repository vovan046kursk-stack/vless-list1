(function () {
    'use strict';

    function startPlugin() {

        console.log('PLUGIN STARTED');

        Lampa.Component.add('test_online', {
            template: '<div></div>',

            init: function () {
                this.render(`
                    <div style="padding:20px">
                        <h1>🔥 Плагин работает</h1>
                        <button id="btn">Нажми меня</button>
                    </div>
                `);

                setTimeout(() => {
                    let btn = document.getElementById('btn');
                    if (btn) {
                        btn.onclick = () => {
                            alert('ВСЁ РАБОТАЕТ 💀');
                        };
                    }
                }, 500);
            }
        });

        Lampa.Menu.add({
            title: '🔥 TEST',
            component: 'test_online',
            icon: 'movie'
        });
    }

    if (window.Lampa) {
        startPlugin();
    } else {
        window.addEventListener('lampa:ready', startPlugin);
    }

})();
