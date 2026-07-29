const crypto = require('crypto');

/**
 * Generate signed URLs for secure video access
 * Prevents direct video URL exposure
 */
class SignedUrlService {
  constructor() {
    this.secret = process.env.JWT_SECRET || 'default-secret';
    this.defaultExpiry = 60 * 60; // 1 hour in seconds
  }

  /**
   * Generate a signed URL with expiry
   * @param {string} baseUrl - The actual video/file URL
   * @param {number} expirySeconds - URL validity duration
   * @returns {string} Signed URL
   */
  generateSignedUrl(baseUrl, expirySeconds = this.defaultExpiry) {
    const expires = Math.floor(Date.now() / 1000) + expirySeconds;
    const payload = `${baseUrl}:${expires}`;
    const signature = crypto
      .createHmac('sha256', this.secret)
      .update(payload)
      .digest('hex');

    const separator = baseUrl.includes('?') ? '&' : '?';
    return `${baseUrl}${separator}expires=${expires}&signature=${signature}`;
  }

  /**
   * Verify a signed URL
   * @param {string} url - The signed URL to verify
   * @returns {boolean} Whether the URL is valid
   */
  verifySignedUrl(url) {
    try {
      const urlObj = new URL(url);
      const expires = urlObj.searchParams.get('expires');
      const signature = urlObj.searchParams.get('signature');

      if (!expires || !signature) return false;

      // Check expiry
      if (parseInt(expires) < Math.floor(Date.now() / 1000)) {
        return false; // URL has expired
      }

      // Reconstruct the base URL without params
      urlObj.searchParams.delete('expires');
      urlObj.searchParams.delete('signature');
      const baseUrl = urlObj.toString();

      // Verify signature
      const payload = `${baseUrl}:${expires}`;
      const expectedSignature = crypto
        .createHmac('sha256', this.secret)
        .update(payload)
        .digest('hex');

      return crypto.timingSafeEqual(
        Buffer.from(signature),
        Buffer.from(expectedSignature)
      );
    } catch (error) {
      console.error('URL verification error:', error);
      return false;
    }
  }

  /**
   * Generate encrypted link for episode access
   * @param {string} episodeId 
   * @param {string} quality 
   * @param {string} userId 
   * @returns {string} Encrypted token
   */
  generateAccessLink(episodeId, quality, userId) {
    const data = JSON.stringify({
      episodeId,
      quality,
      userId,
      timestamp: Date.now()
    });

    const cipher = crypto.createCipher('aes-256-cbc', this.secret);
    let encrypted = cipher.update(data, 'utf8', 'hex');
    encrypted += cipher.final('hex');

    return encrypted;
  }

  /**
   * Verify encrypted access link
   * @param {string} token 
   * @returns {object|null} Decrypted data or null if invalid
   */
  verifyAccessLink(token) {
    try {
      const decipher = crypto.createDecipher('aes-256-cbc', this.secret);
      let decrypted = decipher.update(token, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      const data = JSON.parse(decrypted);

      // Check if token is not too old (24 hours max)
      const maxAge = 24 * 60 * 60 * 1000;
      if (Date.now() - data.timestamp > maxAge) {
        return null;
      }

      return data;
    } catch (error) {
      return null;
    }
  }
}

module.exports = new SignedUrlService();
