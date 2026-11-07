const express = require("express");
const { Pool } = require("pg");

const pool = new Pool({
  host: process.env.DB_HOST || "postgres-db",
  port: 5432,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB,
});

const app = express();
app.use(express.json());

async function initDb(retries = 15) {
  for (let i = 1; i <= retries; i++) {
    try {
      await pool.query(
        `CREATE TABLE IF NOT EXISTS todos (
           id SERIAL PRIMARY KEY,
           title TEXT NOT NULL,
           done BOOLEAN NOT NULL DEFAULT FALSE
         )`
      );
      console.log("DB ready");
      return;
    } catch (err) {
      console.log(`DB not ready (${i}/${retries}): ${err.message}`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  process.exit(1);
}

app.get("/health", (_req, res) => res.json({ status: "ok" }));

app.get("/todos", async (_req, res) => {
  const { rows } = await pool.query("SELECT * FROM todos ORDER BY id");
  res.json(rows);
});

app.post("/todos", async (req, res) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: "title required" });
  const { rows } = await pool.query(
    "INSERT INTO todos (title) VALUES ($1) RETURNING *",
    [title]
  );
  res.status(201).json(rows[0]);
});

app.put("/todos/:id", async (req, res) => {
  const { rows } = await pool.query(
    "UPDATE todos SET done = NOT done WHERE id = $1 RETURNING *",
    [req.params.id]
  );
  if (!rows.length) return res.sendStatus(404);
  res.json(rows[0]);
});

app.delete("/todos/:id", async (req, res) => {
  await pool.query("DELETE FROM todos WHERE id = $1", [req.params.id]);
  res.sendStatus(204);
});

app.get("/", (_req, res) => {
  res.send(`<!doctype html><meta charset="utf-8"><title>Todo</title>
<body style="font-family:sans-serif;max-width:480px;margin:2rem auto">
<h2>Todo list</h2>
<input id="t" placeholder="New task"> <button onclick="add()">Add</button>
<ul id="l"></ul>
<script>
async function load(){
  const r = await (await fetch('/todos')).json();
  document.getElementById('l').innerHTML = r.map(x =>
    '<li><span onclick="tog('+x.id+')" style="cursor:pointer;'+(x.done?'text-decoration:line-through':'')+'">'
    + x.title.replace(/</g,'&lt;') + '</span> <button onclick="del('+x.id+')">x</button></li>').join('');
}
async function add(){
  const i = document.getElementById('t');
  if(!i.value) return;
  await fetch('/todos',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({title:i.value})});
  i.value=''; load();
}
async function tog(id){ await fetch('/todos/'+id,{method:'PUT'}); load(); }
async function del(id){ await fetch('/todos/'+id,{method:'DELETE'}); load(); }
load();
</script></body>`);
});

initDb().then(() => {
  app.listen(3000, "0.0.0.0", () => console.log("Listening on 3000"));
});
