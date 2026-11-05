import { MessageCircle, Send, Smartphone } from 'lucide-react';

interface WhatsAppContactProps {
  phone: string;
  onPhoneChange: (phone: string) => void;
}

export default function WhatsAppContact({ phone, onPhoneChange }: WhatsAppContactProps) {
  return (
    <section className="contact-card panel-glow">
      <div className="section-kicker"><MessageCircle size={14} /> Live comms</div>
      <div className="contact-card-head">
        <div>
          <h2>Keep students in the loop</h2>
          <p>One verified number for SMS and WhatsApp alerts.</p>
        </div>
        <div className="status-dot"><span /> Ready</div>
      </div>
      <label className="field-label" htmlFor="contact-number">Coordinator mobile</label>
      <div className="phone-field">
        <Smartphone size={17} />
        <input id="contact-number" value={phone} onChange={(event) => onPhoneChange(event.target.value)} placeholder="+91 XXXXXXXXXX" inputMode="tel" pattern="\\+91\\s?[0-9]{10}" title="Enter +91 followed by ten numeric digits" />
        <button className="icon-button" aria-label="Send test notification"><Send size={16} /></button>
      </div>
      <div className="channel-row"><span className="channel active"><MessageCircle size={14} /> WhatsApp</span><span className="channel"><Smartphone size={14} /> Text message</span></div>
    </section>
  );
}
