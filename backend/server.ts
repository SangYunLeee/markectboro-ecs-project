import express, { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { DynamoDBClient, PutItemCommand, GetItemCommand, ScanCommand, DeleteItemCommand } from '@aws-sdk/client-dynamodb';

const dynamodbClient = new DynamoDBClient({ region: 'ap-northeast-2' });

const tableName = process.env.DYNAMODB_TABLE_NAME;

const app = express();
const port = process.env.PORT;

// Middleware to parse JSON
app.use(express.json());

// GET /items
app.get('/items', async (req: Request, res: Response) => {
  try {
    const scanCommand = new ScanCommand({ TableName: tableName });
    const response = await dynamodbClient.send(scanCommand);
    console.log("response: ", response.Items);
    res.json(response.Items);
  } catch (error) {
    console.error('Error scanning DynamoDB table:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// GET /items/:id
app.get('/items/:id', async (req: Request, res: Response) => {
  const itemId = req.params.id;

  try {
    const getItemCommand = new GetItemCommand({ TableName: tableName, Key: { id: { S: itemId } } });

    const response = await dynamodbClient.send(getItemCommand);

    if (response.Item) {
      const { id, title, description } = response.Item;
      res.json({ id: id.S, title: title.S, description: description.S });
    } else {
      res.status(404).json({ message: 'item not found' });
    }
  } catch (error) {
    console.error('Error getting item from DynamoDB:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// POST /items
app.post('/items', async (req: Request, res: Response) => {
  const { title, description } = req.body;
  const id = uuidv4(); // Generate a new UUID

  try {
    const putItemCommand = new PutItemCommand({
      TableName: tableName,
      Item: {
        id: { S: id },
        title: { S: title },
        author: { S: description },
      },
    });

    await dynamodbClient.send(putItemCommand);
    res.status(201).json({ id, title, description });
  } catch (error) {
    console.error('Error saving book to DynamoDB:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// PUT /items/:id
app.put('/items/:id', async (req: Request, res: Response) => {
  const itemId = req.params.id;
  const { title, description } = req.body;

  try {
    const getItemCommand = new GetItemCommand({ TableName: tableName, Key: { id: { S: itemId } } });
    const getItemResponse = await dynamodbClient.send(getItemCommand);

    if (getItemResponse.Item) {
      const putItemCommand = new PutItemCommand({
        TableName: tableName,
        Item: {
          id: { S: itemId },
          title: { S: title },
          description: { S: description },
        },
      });

      await dynamodbClient.send(putItemCommand);
      res.json({ id: itemId, title, description });
    } else {
      res.status(404).json({ message: 'Book not found' });
    }
  } catch (error) {
    console.error('Error updating book in DynamoDB:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

// DELETE /items/:id
app.delete('/items/:id', async (req: Request, res: Response) => {
  const itemId = req.params.id;

  try {
    const deleteItemCommand = new DeleteItemCommand({
      TableName: tableName,
      Key: { id: { S: itemId } },
      ReturnValues: 'ALL_OLD',
    });

    const response = await dynamodbClient.send(deleteItemCommand);

    if (response.Attributes) {
      res.json(response.Attributes);
    } else {
      res.status(404).json({ message: 'Item not found' });
    }
  } catch (error) {
    console.error('Error deleting book from DynamoDB:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
});

app.get('/', (req, res) => {
  res.status(200).send('server is alive');
})

// Start the server
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
