const { Webhook } = require('svix');
const User = require('../models/User');

const clerkWebhookHandler = async (req, res) => {
  const WEBHOOK_SECRET = process.env.CLERK_WEBHOOK_SECRET;

  if (!WEBHOOK_SECRET) {
    console.error('CLERK_WEBHOOK_SECRET is not set');
    return res.status(500).json({ message: 'Webhook secret not configured' });
  }

  // Get headers
  const svix_id = req.headers['svix-id'];
  const svix_timestamp = req.headers['svix-timestamp'];
  const svix_signature = req.headers['svix-signature'];

  if (!svix_id || !svix_timestamp || !svix_signature) {
    return res.status(400).json({ message: 'Missing svix headers' });
  }

  // Create Svix instance
  const wh = new Webhook(WEBHOOK_SECRET);

  let evt;
  try {
    evt = wh.verify(JSON.stringify(req.body), {
      'svix-id': svix_id,
      'svix-timestamp': svix_timestamp,
      'svix-signature': svix_signature
    });
  } catch (err) {
    console.error('Webhook verification failed:', err.message);
    return res.status(400).json({ message: 'Webhook verification failed' });
  }

  const { type, data } = evt;

  try {
    switch (type) {
      case 'user.created':
        await handleUserCreated(data);
        break;
      case 'user.updated':
        await handleUserUpdated(data);
        break;
      case 'user.deleted':
        await handleUserDeleted(data);
        break;
      default:
        console.log(`Unhandled webhook type: ${type}`);
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error(`Webhook handler error (${type}):`, error);
    res.status(500).json({ message: 'Webhook handler error' });
  }
};

const handleUserCreated = async (data) => {
  const { id, email_addresses, first_name, last_name, image_url } = data;

  const primaryEmail = email_addresses?.find(e => e.id === data.primary_email_address_id);
  const email = primaryEmail?.email_address || email_addresses?.[0]?.email_address || '';
  const name = [first_name, last_name].filter(Boolean).join(' ') || 'User';

  // Check if user already exists
  const existingUser = await User.findOne({ clerkId: id });
  if (existingUser) {
    console.log(`User ${id} already exists, updating...`);
    return handleUserUpdated(data);
  }

  const user = new User({
    clerkId: id,
    email: email.toLowerCase(),
    name,
    avatar: image_url || '',
    role: 'user',
    isPremium: false
  });

  await user.save();
  console.log(`✅ New user created: ${email}`);
};

const handleUserUpdated = async (data) => {
  const { id, email_addresses, first_name, last_name, image_url } = data;

  const primaryEmail = email_addresses?.find(e => e.id === data.primary_email_address_id);
  const email = primaryEmail?.email_address || email_addresses?.[0]?.email_address || '';
  const name = [first_name, last_name].filter(Boolean).join(' ') || 'User';

  await User.findOneAndUpdate(
    { clerkId: id },
    {
      email: email.toLowerCase(),
      name,
      avatar: image_url || ''
    },
    { new: true }
  );

  console.log(`✅ User updated: ${email}`);
};

const handleUserDeleted = async (data) => {
  const { id } = data;

  // Soft delete - deactivate user
  await User.findOneAndUpdate(
    { clerkId: id },
    { isActive: false }
  );

  console.log(`✅ User deactivated: ${id}`);
};

module.exports = { clerkWebhookHandler };
