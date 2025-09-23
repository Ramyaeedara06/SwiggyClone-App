const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Swiggy Clone - Hello!' });
});

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// sample endpoint: list restaurants (static)
app.get('/restaurants', (req, res) => {
  res.json([
    { id: 1, name: 'Pizza Place', cuisine: 'Italian' },
    { id: 2, name: 'Samosa Corner', cuisine: 'Indian' }
  ]);
});

if (require.main === module) {
  app.listen(port, () => {
    console.log(`Server listening on port ${port}`);
  });
}

module.exports = app; // for tests
