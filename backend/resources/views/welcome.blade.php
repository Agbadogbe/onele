<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Onélé — API</title>
    {{-- Page volontairement autonome : aucun asset à compiler, donc rien qui
         puisse échouer sur une installation neuve. --}}
    <style>
        :root{
            color-scheme:light dark;
            --paper:#ECF1EF; --surface:#fff; --ink:#0F1D1A; --muted:#63776F;
            --line:#E1E8E4; --brand:#17506E; --brand-hi:#2AA8C4; --ok:#1E7A4E;
        }
        @media (prefers-color-scheme:dark){
            :root{--paper:#0D1614; --surface:#141F1D; --ink:#E6EEEA;
                  --muted:#8FA79D; --line:#22302C;}
        }
        *{box-sizing:border-box;}
        body{
            margin:0; min-height:100vh; display:grid; place-items:center;
            padding:32px; background:var(--paper); color:var(--ink);
            font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
        }
        .carte{
            width:100%; max-width:520px; background:var(--surface);
            border:1px solid var(--line); border-radius:18px; padding:30px 28px;
            box-shadow:0 2px 8px rgba(14,28,24,.06), 0 20px 48px rgba(14,28,24,.10);
        }
        .marque{display:flex; align-items:center; gap:12px; margin-bottom:22px;}
        .tuile{
            width:38px; height:38px; flex:none; border-radius:12px;
            background:linear-gradient(135deg,var(--brand),var(--brand-hi));
            display:grid; place-items:center;
        }
        h1{margin:0; font-size:1.25rem; letter-spacing:-.02em;}
        .etat{
            display:inline-flex; align-items:center; gap:8px; margin-bottom:18px;
            padding:5px 12px 5px 10px; border-radius:999px;
            background:rgba(30,122,78,.12); color:var(--ok);
            font-size:.78rem; font-weight:600;
        }
        .etat i{width:7px; height:7px; border-radius:50%; background:currentColor;}
        p{margin:0 0 18px; color:var(--muted);}
        dl{margin:0; display:grid; grid-template-columns:auto 1fr; gap:8px 16px;
           padding-top:18px; border-top:1px solid var(--line); font-size:.88rem;}
        dt{color:var(--muted);}
        dd{margin:0; font-family:ui-monospace,SFMono-Regular,Menlo,monospace;}
        a{color:var(--brand-hi); font-weight:600;}
    </style>
</head>
<body>
    <main class="carte">
        <div class="marque">
            <span class="tuile">
                <svg viewBox="0 0 100 100" width="26" height="26" aria-hidden="true">
                    <circle cx="50" cy="55" r="21" fill="none" stroke="#fff" stroke-width="9.5"/>
                    <rect x="52" y="10" width="22" height="9.5" rx="4.75" fill="#fff"
                          transform="rotate(35.5 63 14.75)"/>
                </svg>
            </span>
            <h1>Onélé</h1>
        </div>

        <span class="etat"><i></i>L’API répond</span>

        <p>
            Cette adresse sert l’API. L’espace d’administration se trouve sur le
            serveur web, et l’application employé sur mobile.
        </p>

        <dl>
            <dt>Espace admin</dt>
            <dd><a href="http://localhost:5173">localhost:5173</a></dd>
            <dt>Temps réel</dt>
            <dd>{{ config('reverb.servers.reverb.host') }}:{{ config('reverb.servers.reverb.port') }}</dd>
            <dt>Base</dt>
            <dd>{{ config('database.default') }}</dd>
            <dt>Compte admin</dt>
            <dd>admin@onele.test / password</dd>
            <dt>Compte employé</dt>
            <dd>moussa.ndiaye@onele.test / password</dd>
        </dl>
    </main>
</body>
</html>
