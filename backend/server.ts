import express, { Request, Response } from 'express';
import AWS from 'aws-sdk';
import { v4 as uuidv4 } from 'uuid';
import dotenv from 'dotenv';
dotenv.config({
  path: ".env",
});
// Configure the AWS SDK
AWS.config.update({
  region: 'ap-northeast-2',
  accessKeyId: process.env.ACCESS_KEY_ID,
  secretAccessKey: process.env.SECRET_ACCESS_KEY,
});

const dynamodb = new AWS.DynamoDB.DocumentClient();
const tableName = process.env.DYNAMODB_TABLE_NAME;

const app = express();
const port = process.env.PORT;

// Middleware to parse JSON
app.use(express.json());

// GET /items
app.get('/items', (req: Request, res: Response) => {
  const params = {
    TableName: tableName,
  };

  dynamodb.scan(params, (err, data) => {
    if (err) {
      console.error('Error scanning DynamoDB table:', err);
      res.status(500).json({ message: 'Internal server error' });
    } else {
      res.json(data.Items);
    }
  });
});

// GET /items/:id
app.get('/items/:id', (req: Request, res: Response) => {
  const itemId = req.params.id;

  const params = {
    TableName: tableName,
    Key: {
      id: itemId,
    },
  };

  dynamodb.get(params, (err, data) => {
    if (err) {
      console.error('Error getting item from DynamoDB:', err);
      res.status(500).json({ message: 'Internal server error' });
    } else if (!data.Item) {
      res.status(404).json({ message: 'item not found' });
    } else {
      res.json(data.Item);
    }
  });
});

// POST /items
app.post('/items', (req: Request, res: Response) => {
  const { title, description } = req.body;
  const id = uuidv4(); // Generate a new UUID

  const params = {
    TableName: tableName,
    Item: {
      id,
      title,
      description,
    },
  };

  dynamodb.put(params, (err) => {
    if (err) {
      console.error('Error saving item to DynamoDB:', err);
      res.status(500).json({ message: 'Internal server error' });
    } else {
      res.status(201).json(params.Item);
    }
  });
});

// PUT /items/:id
app.put('/items/:id', (req: Request, res: Response) => {
  const itemId = req.params.id;
  const { title, description } = req.body;

  const params = {
    TableName: tableName,
    Item: {
      id: itemId,
      title,
      description,
    },
    ConditionExpression: 'attribute_exists(id)', // Ensure the item with the given ID exists
  };

  dynamodb.put(params, (err) => {
    if (err) {
      if (err.code === 'ConditionalCheckFailedException') {
        res.status(404).json({ message: 'item not found' });
      } else {
        console.error('Error updating item in DynamoDB:', err);
        res.status(500).json({ message: 'Internal server error' });
      }
    } else {
      res.json(params.Item);
    }
  });
});

// DELETE /items/:id
app.delete('/items/:id', (req: Request, res: Response) => {
  const itemId = req.params.id;

  const params = {
    TableName: tableName,
    Key: {
      id: itemId,
    },
    ReturnValues: 'ALL_OLD',
  };

  dynamodb.delete(params, (err, data) => {
    if (err) {
      console.error('Error deleting item from DynamoDB:', err);
      res.status(500).json({ message: 'Internal server error' });
    } else if (!data.Attributes) {
      res.status(404).json({ message: 'item not found' });
    } else {
      res.json(data.Attributes);
    }
  });
});

app.get('/', (req, res) => {
  res.status(200).send('server is alive');
})
// Start the server
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
