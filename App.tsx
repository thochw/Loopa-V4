import React, { useState, useEffect, useRef } from 'react';
import ReactDOM from 'react-dom/client';
import { 
  Globe, MapPin, Calendar, MessageSquare, Search, Bell, Eye, Plus, 
  Compass, List, Filter, Book, Backpack, ChevronRight, ArrowUpRight, SlidersHorizontal,
  Settings, ArrowLeft, CheckCircle2, ShieldAlert, X, Check, Image as ImageIcon, Lock, User,
  Home, Bed, Users, RefreshCw, Map as MapIcon, Star, Locate, MoreHorizontal, ShoppingBag, 
  Building2, Tent, Plane, Briefcase, Smile, UserPlus, Send, ArrowRight
} from 'lucide-react';
import { USERS, GROUPS, HOUSING_SPOTS, ROOMMATES, SWAPS, CHATS, CHAT_MESSAGES, Tab } from './constants';

declare global {
  interface Window {
    mapboxgl: any;
  }
}

// Mapbox Token (remplace par ta clé dans .env ou ici en local)
const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_TOKEN ?? 'YOUR_MAPBOX_PUBLIC_TOKEN';
// Style Mapbox (Streets-based pour queryRenderedFeatures sur POI)
const MAPBOX_STYLE = 'mapbox://styles/thochw/cmkbqgty5004901rxgct4a0z6';

interface POIFeatureData {
  name: string;
  class?: string;
  group?: string;
  maki?: string;
  coordinates: [number, number];
  address?: string;
}

// --- Reusable UI Components ---

interface AvatarProps {
  src: string;
  size?: 'sm' | 'md' | 'lg' | 'xl' | '2xl';
  className?: string;
}

const Avatar: React.FC<AvatarProps> = ({ src, size = 'md', className = '' }) => {
  const sizeClasses = {
    sm: 'w-6 h-6',
    md: 'w-8 h-8',
    lg: 'w-10 h-10',
    xl: 'w-12 h-12',
    '2xl': 'w-24 h-24',
  };
  return (
    <img 
      src={src} 
      alt="avatar" 
      className={`rounded-full object-cover border-2 border-white ${sizeClasses[size]} ${className}`} 
    />
  );
};

interface AvatarStackProps {
  avatars: string[];
  count?: number;
  size?: 'sm' | 'md';
}

const AvatarStack: React.FC<AvatarStackProps> = ({ avatars, count, size = 'sm' }) => {
  return (
    <div className="flex -space-x-2 items-center">
      {avatars.slice(0, 3).map((src, i) => (
        <Avatar key={i} src={src} size={size} className="border-white" />
      ))}
      {count && (
        <div className={`flex items-center justify-center rounded-full bg-white text-xs font-bold text-gray-600 border-2 border-white ${size === 'sm' ? 'w-6 h-6' : 'w-8 h-8'}`}>
          +{count}
        </div>
      )}
    </div>
  );
};

interface IconButtonProps {
  children: React.ReactNode;
  onClick?: () => void;
  active?: boolean;
  className?: string;
}

const IconButton: React.FC<IconButtonProps> = ({ children, onClick, active = false, className = '' }) => (
  <button 
    onClick={onClick}
    className={`p-2.5 rounded-full shadow-sm flex items-center justify-center transition-colors ${active ? 'bg-blue-500 text-white' : 'bg-white text-gray-700'} ${className}`}
  >
    {children}
  </button>
);

const Badge = ({ count }: { count: number }) => (
  <div className="absolute top-0 right-0 bg-red-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full min-w-[16px] text-center border-2 border-white transform translate-x-1/4 -translate-y-1/4">
    {count}
  </div>
);

// --- Marker Components for Mapbox ---

const GroupMarker1 = ({ group }: { group: any }) => (
  <div className="flex items-center cursor-pointer">
      <div className="bg-white p-1 rounded-full shadow-lg relative z-10">
        <img src={group.image} className="w-12 h-12 rounded-full object-cover" />
      </div>
      <div className="bg-white/90 backdrop-blur-sm px-3 py-1 rounded-r-xl shadow-md -ml-3 pl-4 text-xs font-bold text-gray-800 max-w-[120px] truncate">
        {group.title}
      </div>
  </div>
);

const GroupMarker2 = ({ group }: { group: any }) => (
  <div className="flex items-center cursor-pointer relative z-20">
      <div className="bg-white p-1 rounded-full shadow-xl border border-gray-100 relative z-10 scale-110">
        <div className="w-14 h-14 rounded-full bg-gray-100 flex flex-wrap gap-0.5 p-1 overflow-hidden content-center justify-center">
          <span className="text-[10px]">🚀</span>
          <span className="text-[10px]">🥘</span>
          <span className="text-[10px]">🚋</span>
          <span className="text-[10px] text-blue-500 font-bold">888</span>
          <div className="w-full text-[8px] text-center font-bold leading-none mt-0.5">Weekly Hangout</div>
        </div>
      </div>
      <div className="bg-white px-3 py-2 rounded-r-xl shadow-md -ml-4 pl-5 text-xs font-bold text-gray-800 max-w-[140px]">
        Weekly hangout, ( art,
      </div>
      {/* Blue Dot Indicator */}
      <div className="absolute -top-1 right-2 w-4 h-4 bg-blue-500 rounded-full border-2 border-white z-30"></div>
  </div>
);

const TravelerMarker = ({ user, large = false }: { user: any, large?: boolean }) => (
  <div className={`relative p-0.5 rounded-full bg-white shadow-md cursor-pointer transition-transform hover:scale-110 ${large ? 'scale-125 z-20' : 'scale-100 z-10'}`}>
      <img src={user.image} className="w-12 h-12 rounded-full object-cover border border-gray-100" />
      <div className="absolute top-0.5 right-0.5 w-3.5 h-3.5 bg-green-500 rounded-full border-[2px] border-white z-30"></div>
  </div>
);

const HousingMarker = ({ item, type }: { item: any, type: 'spot' | 'roommate' | 'swap' }) => (
  <div className="flex flex-col items-center cursor-pointer hover:scale-110 transition-transform z-20">
      <div className={`p-1 rounded-full shadow-lg relative z-10 border-2 ${type === 'spot' ? 'bg-white border-blue-500' : type === 'roommate' ? 'bg-white border-green-500' : 'bg-white border-purple-500'}`}>
         {type === 'spot' ? (
           <span className="font-bold text-xs px-1 text-gray-900">${item.price}</span>
         ) : type === 'roommate' ? (
           <img src={item.image} className="w-8 h-8 rounded-full object-cover" />
         ) : (
           <RefreshCw size={16} className="text-purple-500 m-1" />
         )}
      </div>
      <div className="w-1 h-3 bg-gray-400 rounded-full mt-[-2px] shadow-sm"></div>
      <div className="w-2 h-1 bg-black/20 rounded-full blur-[1px]"></div>
  </div>
);

const MeMarker = () => (
  <div className="relative cursor-pointer">
    <div className="absolute inset-0 rounded-full border-4 border-blue-400/30 animate-ping"></div>
    <div className="p-1 bg-white rounded-full shadow-2xl relative z-10">
      <img src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80" className="w-20 h-20 rounded-full object-cover" />
    </div>
    <div className="absolute top-2 right-2 w-5 h-5 bg-green-500 rounded-full border-[3px] border-white z-20"></div>
  </div>
);

// --- Create Group Flow Components ---

const ProgressBar = ({ currentStep, totalSteps }: { currentStep: number, totalSteps: number }) => {
  return (
    <div className="flex gap-2 mb-8">
      {Array.from({ length: totalSteps }).map((_, i) => (
        <div 
          key={i} 
          className={`h-1 flex-1 rounded-full ${i <= currentStep ? 'bg-blue-500' : 'bg-gray-200'}`}
        />
      ))}
    </div>
  );
};

const CreateGroupFlow = ({ onClose }: { onClose: () => void }) => {
  const [step, setStep] = useState(0); // 0: Intro, 1: Details, 2: Location, 3: Privacy, 4: Interests
  const [formData, setFormData] = useState({
    name: '',
    privacy: 'public',
    duration: 7,
    description: '',
    interests: [] as string[]
  });

  const nextStep = () => {
    if (step < 4) setStep(step + 1);
    else onClose();
  };

  const prevStep = () => {
    if (step > 0) setStep(step - 1);
    else onClose();
  };

  const toggleInterest = (interest: string) => {
    if (formData.interests.includes(interest)) {
      setFormData({ ...formData, interests: formData.interests.filter(i => i !== interest) });
    } else {
      if (formData.interests.length < 5) {
        setFormData({ ...formData, interests: [...formData.interests, interest] });
      }
    }
  };

  // Step 0: Intro
  if (step === 0) {
    return (
      <div className="fixed inset-0 z-[60] bg-white flex flex-col">
        {/* Header */}
        <div className="px-5 pt-4 flex justify-between items-center">
            <button onClick={onClose}><X size={24} className="text-gray-900" /></button>
        </div>
        
        <div className="flex-1 flex flex-col items-center px-6 pt-4 overflow-hidden relative">
           <h1 className="text-3xl font-bold text-center mb-4 flex items-center gap-2">
             Create nearby group <Globe className="text-blue-500 fill-blue-500/20" />
           </h1>
           <p className="text-center text-gray-500 mb-8 max-w-xs leading-relaxed text-sm">
             Connect with travelers near you. This group will ONLY be visible to people around your current area
           </p>

           {/* Faux Map Visual */}
           <div className="w-full flex-1 relative bg-blue-50 rounded-t-[40px] overflow-hidden shadow-inner border-t border-gray-100">
              {/* Map Image Background */}
              <div className="absolute inset-0 opacity-40 mix-blend-multiply" style={{ backgroundImage: 'url("https://api.mapbox.com/styles/v1/mapbox/light-v10/static/-73.5673,45.5017,13,0,0/600x800?access_token=' + MAPBOX_TOKEN + '")', backgroundSize: 'cover' }}></div>
              <div className="absolute inset-0 bg-gradient-to-b from-white via-transparent to-white/80"></div>

              {/* Center Profile Pin */}
              <div className="absolute top-1/3 left-1/2 transform -translate-x-1/2 -translate-y-1/2 flex flex-col items-center z-10">
                 <div className="w-32 h-32 rounded-full border-[6px] border-blue-100 bg-blue-50 flex items-center justify-center shadow-xl">
                    <div className="w-24 h-24 rounded-full border-4 border-white overflow-hidden shadow-lg">
                       <img src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80" className="w-full h-full object-cover" />
                    </div>
                 </div>
                 <div className="bg-white px-4 py-1.5 rounded-full shadow-md font-bold text-lg -mt-4 z-20">Montreal</div>
              </div>

              {/* Faux Group Cards */}
              <div className="absolute bottom-0 left-0 right-0 p-6 space-y-3">
                 <div className="bg-white/80 backdrop-blur-sm p-3 rounded-2xl flex items-center gap-3 shadow-sm border border-white/50 transform scale-95 opacity-60">
                    <img src="https://images.unsplash.com/photo-1570554886111-e80fcca9402d?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80" className="w-12 h-12 rounded-full object-cover" />
                    <div className="font-bold text-gray-800">Drinks in Montréal</div>
                 </div>
                 <div className="bg-white/90 backdrop-blur-md p-3 rounded-2xl flex items-center gap-3 shadow-lg border border-white/50">
                    <img src="https://images.unsplash.com/photo-1511632765486-a01980e01a18?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80" className="w-12 h-12 rounded-full object-cover" />
                    <div>
                       <div className="font-bold text-gray-800">Dinner plans in Montréal</div>
                       <AvatarStack avatars={GROUPS[1].avatars} count={59} size="sm" />
                    </div>
                 </div>
              </div>
           </div>
        </div>

        <div className="p-6 safe-bottom">
           <button onClick={nextStep} className="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-4 rounded-full shadow-lg shadow-blue-500/30 transition-all active:scale-[0.98]">
             Continue
           </button>
        </div>
      </div>
    );
  }

  // Steps 1-4 Wrapper
  return (
    <div className="fixed inset-0 z-[60] bg-white flex flex-col animate-in slide-in-from-right duration-300">
      {/* Header */}
      <div className="px-5 pt-4 pb-2">
         <div className="flex justify-between items-center mb-6">
            <button onClick={prevStep}><ArrowLeft size={24} className="text-gray-900" /></button>
            <span className="font-bold text-lg">Create nearby group</span>
            <div className="w-6"></div> {/* Spacer */}
         </div>
         <ProgressBar currentStep={step - 1} totalSteps={4} />
      </div>

      <div className="flex-1 overflow-y-auto px-6 no-scrollbar">
        {step === 1 && (
          <div className="animate-in fade-in duration-300">
             <h2 className="text-2xl font-bold mb-4">Name your group</h2>
             <input 
               type="text" 
               placeholder="Enter Name" 
               className="w-full bg-gray-50 border-none rounded-2xl py-4 px-5 text-lg font-medium focus:ring-2 focus:ring-blue-500 mb-3"
               value={formData.name}
               onChange={(e) => setFormData({...formData, name: e.target.value})}
             />
             <div className="flex items-center gap-2 text-gray-400 text-sm mb-8">
               <span className="w-4 h-4 border border-gray-400 rounded-full flex items-center justify-center text-[10px]">i</span>
               No more than 60 characters
             </div>

             <h2 className="text-xl font-bold mb-4">Add a group photo</h2>
             <div className="w-full aspect-[4/3] bg-gray-100 rounded-3xl flex items-center justify-center border-2 border-dashed border-gray-200 cursor-pointer hover:bg-gray-50 transition-colors">
                <ImageIcon size={48} className="text-gray-300" />
             </div>
          </div>
        )}

        {step === 2 && (
          <div className="h-full flex flex-col animate-in fade-in duration-300">
             <h2 className="text-2xl font-bold mb-1">Group Location</h2>
             <p className="text-gray-500 mb-6">Choose a general area</p>
             
             <div className="flex-1 bg-gray-100 rounded-3xl overflow-hidden relative shadow-inner border border-gray-200">
                <div className="absolute inset-0" style={{ backgroundImage: 'url("https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/-73.5673,45.5017,14,0,0/600x800?access_token=' + MAPBOX_TOKEN + '")', backgroundSize: 'cover' }}></div>
                <div className="absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 pb-8">
                   <div className="relative">
                      <MapPin size={48} className="text-blue-500 fill-blue-500 animate-bounce" />
                      <div className="w-4 h-2 bg-black/20 rounded-full blur-sm absolute bottom-0 left-1/2 -translate-x-1/2"></div>
                   </div>
                </div>
                <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-white px-4 py-2 rounded-full shadow-lg font-bold text-sm flex items-center gap-2">
                   <MapPin size={14} className="text-blue-500" /> Montreal
                </div>
             </div>
          </div>
        )}

        {step === 3 && (
          <div className="animate-in fade-in duration-300">
             <h2 className="text-2xl font-bold mb-1">Group privacy</h2>
             <p className="text-gray-500 mb-6">Who can join your group?</p>

             <div className="space-y-3 mb-10">
                <button 
                  onClick={() => setFormData({...formData, privacy: 'public'})}
                  className={`w-full p-4 rounded-2xl border-2 flex items-center gap-4 transition-all ${formData.privacy === 'public' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white'}`}
                >
                   <div className={`w-12 h-12 rounded-full flex items-center justify-center ${formData.privacy === 'public' ? 'bg-blue-100 text-blue-500' : 'bg-gray-100 text-gray-500'}`}>
                      <Globe size={24} />
                   </div>
                   <div className="text-left">
                      <div className={`font-bold ${formData.privacy === 'public' ? 'text-blue-900' : 'text-gray-900'}`}>Public</div>
                      <div className="text-xs text-gray-500">Anyone nearby can join</div>
                   </div>
                   <div className="flex-1"></div>
                   <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${formData.privacy === 'public' ? 'border-blue-500 bg-blue-500' : 'border-gray-300'}`}>
                      {formData.privacy === 'public' && <div className="w-2.5 h-2.5 bg-white rounded-full"></div>}
                   </div>
                </button>

                <button 
                  onClick={() => setFormData({...formData, privacy: 'private'})}
                  className={`w-full p-4 rounded-2xl border-2 flex items-center gap-4 transition-all ${formData.privacy === 'private' ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white'}`}
                >
                   <div className={`w-12 h-12 rounded-full flex items-center justify-center ${formData.privacy === 'private' ? 'bg-blue-100 text-blue-500' : 'bg-gray-100 text-gray-500'}`}>
                      <Lock size={24} />
                   </div>
                   <div className="text-left">
                      <div className={`font-bold ${formData.privacy === 'private' ? 'text-blue-900' : 'text-gray-900'}`}>Private</div>
                      <div className="text-xs text-gray-500">Only people with the link</div>
                   </div>
                   <div className="flex-1"></div>
                   <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center ${formData.privacy === 'private' ? 'border-blue-500 bg-blue-500' : 'border-gray-300'}`}>
                      {formData.privacy === 'private' && <div className="w-2.5 h-2.5 bg-white rounded-full"></div>}
                   </div>
                </button>
             </div>

             <h2 className="text-xl font-bold mb-1">Group duration</h2>
             <p className="text-gray-500 mb-6">How long should your group stay active?</p>
             
             <div className="px-2">
               <input 
                 type="range" 
                 min="1" 
                 max="14" 
                 value={formData.duration} 
                 onChange={(e) => setFormData({...formData, duration: parseInt(e.target.value)})}
                 className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer accent-blue-500"
               />
               <div className="flex justify-center mt-4">
                  <div className="bg-gray-900 text-white px-4 py-1.5 rounded-full font-bold text-sm flex items-center gap-2">
                     <Calendar size={14} /> {formData.duration} days
                  </div>
               </div>
             </div>
          </div>
        )}

        {step === 4 && (
          <div className="animate-in fade-in duration-300 pb-10">
             <div className="flex justify-between items-baseline mb-1">
               <h2 className="text-2xl font-bold">About your trip</h2>
               <span className="text-gray-400 text-sm">Optional</span>
             </div>
             
             <textarea 
               placeholder="Type something..." 
               className="w-full h-32 bg-gray-50 border-none rounded-2xl p-4 text-base font-medium focus:ring-2 focus:ring-blue-500 mb-8 resize-none"
               value={formData.description}
               onChange={(e) => setFormData({...formData, description: e.target.value})}
             />

             <div className="flex justify-between items-baseline mb-4">
               <h2 className="text-xl font-bold">Select interests</h2>
               <span className="text-gray-400 text-sm">5 max</span>
             </div>

             <div className="flex flex-wrap gap-2">
               {[
                 { label: 'Adventure', icon: '🧗' },
                 { label: 'Au Pair', icon: '🌎' },
                 { label: 'Backpacking', icon: '🎒' },
                 { label: 'Beach', icon: '🏖️' },
                 { label: 'Budget Travel', icon: '💵' },
                 { label: 'Camping', icon: '⛺' },
                 { label: 'Cruise', icon: '🚢' },
                 { label: 'Digital Nomad', icon: '💻' },
                 { label: 'Diving', icon: '🤿' },
                 { label: 'Hiking', icon: '🥾' },
                 { label: 'Hostel', icon: '🛏️' },
                 { label: 'Interrail', icon: '🚄' },
                 { label: 'Living Abroad', icon: '💼' },
                 { label: 'Luxury Travel', icon: '🍸' },
                 { label: 'Nature', icon: '🌿' }
               ].map((interest) => (
                 <button 
                   key={interest.label}
                   onClick={() => toggleInterest(interest.label)}
                   className={`px-4 py-2.5 rounded-full border flex items-center gap-2 font-bold text-sm transition-all active:scale-95 ${
                     formData.interests.includes(interest.label) 
                       ? 'border-blue-500 bg-blue-50 text-blue-600' 
                       : 'border-gray-200 bg-white text-gray-700 hover:border-gray-300'
                   }`}
                 >
                   <span>{interest.icon}</span> {interest.label}
                 </button>
               ))}
             </div>
          </div>
        )}
      </div>

      <div className="p-6 border-t border-gray-100 safe-bottom bg-white">
         <button onClick={nextStep} className="w-full bg-blue-500 hover:bg-blue-600 text-white font-bold py-4 rounded-full shadow-lg shadow-blue-500/30 transition-all active:scale-[0.98]">
           {step === 4 ? 'Continue' : 'Continue'}
         </button>
      </div>
    </div>
  );
};

// --- Screen Components ---

// 1. Explore / Map Screen
interface ExploreScreenProps {
  variant: 'groups' | 'travelers';
  onProfileClick: (user: any) => void;
  onFilterClick: () => void;
  onAddGroupClick: () => void; // Added Prop
}

const ExploreScreen: React.FC<ExploreScreenProps> = ({ variant, onProfileClick, onFilterClick, onAddGroupClick }) => {
  // Bottom Sheet Logic
  const [isSheetOpen, setIsSheetOpen] = useState(true);
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState(0); 
  const startY = useRef(0);
  const sheetRef = useRef<HTMLDivElement>(null);
  
  // POI sélectionné (clic sur un POI de la carte)
  const [selectedPOI, setSelectedPOI] = useState<POIFeatureData | null>(null);
  const onPOIClickRef = useRef<((data: POIFeatureData) => void) | null>(null);
  onPOIClickRef.current = (data) => setSelectedPOI(data);
  
  // Mapbox Refs
  const mapContainer = useRef<HTMLDivElement>(null);
  const mapRef = useRef<any>(null);
  const markersRef = useRef<{marker: any, root: ReactDOM.Root}[]>([]);

  // Initialize Map avec style Standard (featureset POI)
  useEffect(() => {
    if (!mapContainer.current) return;
    if (mapRef.current) return;

    const mapboxgl = window.mapboxgl;
    if (!mapboxgl) return;

    mapboxgl.accessToken = MAPBOX_TOKEN;
    
    const map = new mapboxgl.Map({
      container: mapContainer.current,
      style: MAPBOX_STYLE,
      center: [-73.5673, 45.5017],
      zoom: 13.5,
      attributionControl: false,
      logoPosition: 'bottom-left'
    });

    mapRef.current = map;

    // Clic sur un POI : addInteraction (Standard) OU fallback queryRenderedFeatures
    const handlePOIClick = (e: { lngLat: { lng: number; lat: number }; point: { x: number; y: number } }) => {
      const mapInstance = mapRef.current;
      if (!mapInstance) return;
      const point = e.point || (e as any).point;
      const lngLat = e.lngLat || (e as any).lngLat;
      if (!point || !lngLat) return;
      // queryRenderedFeatures : récupère les features sous le clic (tous styles Mapbox)
      const allFeatures = mapInstance.queryRenderedFeatures(point);
      const poiFeature = allFeatures.find((f: any) => {
        const p = f?.properties;
        const name = p?.name ?? p?.name_en ?? p?.name_int;
        const isPOILayer = f?.layer?.id && /poi|place|label/.test(String(f.layer.id));
        return name && (isPOILayer || f?.geometry);
      });
      if (poiFeature) {
        const props = poiFeature.properties || {};
        let coords: [number, number] = [lngLat.lng, lngLat.lat];
        const geom = (poiFeature as any).geometry;
        if (geom?.coordinates) {
          const c = Array.isArray(geom.coordinates[0]) ? geom.coordinates[0] : geom.coordinates;
          if (Array.isArray(c) && c.length >= 2) coords = [c[0], c[1]];
        }
        onPOIClickRef.current?.({
          name: (props.name as string) || 'Lieu',
          class: props.class as string | undefined,
          group: props.group as string | undefined,
          maki: props.maki as string | undefined,
          coordinates: coords
        });
        return;
      }
      // Fallback : utiliser les coordonnées du clic si on a cliqué sur la carte (pas de POI)
      // On n'ouvre pas la sheet pour un clic vide
    };

    map.on('click', handlePOIClick);

    return () => {
      map.off('click', handlePOIClick);
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Update Markers when variant changes
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    
    // Clear existing markers and unmount React roots
    markersRef.current.forEach(({ marker, root }) => {
      marker.remove();
      // Schedule unmount to avoid immediate conflict during rendering cycle
      setTimeout(() => root.unmount(), 0);
    });
    markersRef.current = [];

    const mapboxgl = window.mapboxgl;
    if (!mapboxgl) return;

    if (variant === 'groups') {
      // Add Group Markers
      GROUPS.forEach((group, index) => {
        const el = document.createElement('div');
        const root = ReactDOM.createRoot(el);
        
        if (index === 1) {
             root.render(<GroupMarker2 group={group} />);
        } else {
             root.render(<GroupMarker1 group={group} />);
        }
        
        const marker = new mapboxgl.Marker({ element: el, anchor: 'center' })
          .setLngLat([group.lng, group.lat])
          .addTo(map);
        
        markersRef.current.push({ marker, root });
      });

      // Add simple 'train' marker simulation
      const trainEl = document.createElement('div');
      const trainRoot = ReactDOM.createRoot(trainEl);
      trainRoot.render(
         <div className="bg-blue-500 p-1.5 rounded text-white shadow-lg cursor-pointer transform transition-transform hover:scale-110">
            <div className="text-[10px] font-bold">🚆</div>
         </div>
      );
      const trainMarker = new mapboxgl.Marker({ element: trainEl })
          .setLngLat([-73.5720, 45.4980])
          .addTo(map);
      markersRef.current.push({ marker: trainMarker, root: trainRoot });

    } else {
      // Add Traveler Markers
      USERS.forEach((user, index) => {
         const el = document.createElement('div');
         const root = ReactDOM.createRoot(el);
         root.render(<TravelerMarker user={user} large={index === 0} />);
         
         const marker = new mapboxgl.Marker({ element: el, anchor: 'center' })
            .setLngLat([user.lng, user.lat])
            .addTo(map);
         
         markersRef.current.push({ marker, root });
      });

      // Add Me Marker
      const meEl = document.createElement('div');
      const meRoot = ReactDOM.createRoot(meEl);
      meRoot.render(<MeMarker />);
      const meMarker = new mapboxgl.Marker({ element: meEl, anchor: 'center' })
        .setLngLat([-73.5673, 45.5017]) // Center
        .addTo(map);
      markersRef.current.push({ marker: meMarker, root: meRoot });
    }

  }, [variant, mapRef.current]);

  // Récupérer l'adresse via Mapbox Geocoding (reverse) quand un POI est sélectionné
  useEffect(() => {
    if (!selectedPOI?.coordinates) return;
    const [lng, lat] = selectedPOI.coordinates;
    fetch(
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?access_token=${MAPBOX_TOKEN}&limit=1`
    )
      .then((res) => res.json())
      .then((data) => {
        const place = data?.features?.[0];
        if (place?.place_name) {
          setSelectedPOI((prev) => prev ? { ...prev, address: place.place_name } : null);
        }
      })
      .catch(() => {});
  }, [selectedPOI?.coordinates]);

  // Bottom Sheet Logic (Existing)
  useEffect(() => {
    setIsSheetOpen(true);
    setDragOffset(0);
  }, [variant]);

  const SHEET_HEIGHT_PERCENT = variant === 'groups' ? 35 : 45; 
  const CLOSE_THRESHOLD = 100; 

  const handleTouchStart = (e: React.TouchEvent) => {
    setIsDragging(true);
    startY.current = e.touches[0].clientY;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging) return;
    const deltaY = e.touches[0].clientY - startY.current;
    if (deltaY < -50) return; 
    setDragOffset(deltaY);
  };

  const handleTouchEnd = () => {
    setIsDragging(false);
    if (dragOffset > CLOSE_THRESHOLD) {
      setIsSheetOpen(false);
    } 
    setDragOffset(0);
  };

  const filterChips = [
    { label: 'backpacking', emoji: '🎒' },
    { label: 'digital nomad', emoji: '💻' },
    { label: 'gap year', emoji: '👋' },
    { label: 'studying abroad', emoji: '📚' },
    { label: 'living abroad', emoji: '🏠' },
    { label: 'au pair', emoji: '🤹' },
  ];

  // Mock "Me" user for the header
  const meUser = {
    id: 999,
    name: "Thomas",
    image: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80",
    flag: "🇨🇦"
  };

  return (
    <div className="relative w-full h-full bg-gray-100 overflow-hidden flex flex-col">
      {/* Mapbox Container */}
      <div ref={mapContainer} className="absolute inset-0 z-0" />

      {/* POI Detail Sheet (clic sur un POI de la carte) */}
      {selectedPOI && (
        <div className="absolute inset-0 z-50 flex flex-col justify-end pointer-events-auto">
          <div 
            className="absolute inset-0 bg-black/30"
            onClick={() => setSelectedPOI(null)}
          />
          <div 
            className="relative bg-white rounded-t-3xl shadow-2xl max-h-[70vh] overflow-y-auto safe-bottom"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="sticky top-0 bg-white flex justify-between items-center px-5 py-4 border-b border-gray-100 z-10">
              <h2 className="text-xl font-bold text-gray-900">{selectedPOI.name}</h2>
              <button 
                onClick={() => setSelectedPOI(null)}
                className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center"
              >
                <X size={20} className="text-gray-600" />
              </button>
            </div>
            <div className="p-5 space-y-5">
              {selectedPOI.class && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Catégorie</p>
                  <p className="text-gray-800">{selectedPOI.class.replace(/_/g, ' ')}</p>
                </div>
              )}
              {selectedPOI.address && (
                <div>
                  <p className="text-xs font-semibold text-gray-500 uppercase mb-1">Adresse</p>
                  <p className="text-gray-800">{selectedPOI.address}</p>
                </div>
              )}
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Photos</p>
                <div className="flex gap-2 overflow-x-auto pb-2">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="w-24 h-24 rounded-xl bg-gray-200 flex-shrink-0 flex items-center justify-center">
                      <ImageIcon size={24} className="text-gray-400" />
                    </div>
                  ))}
                  <p className="text-gray-400 text-sm self-center">En attente d'intégration</p>
                </div>
              </div>
              <div>
                <p className="text-xs font-semibold text-gray-500 uppercase mb-2">Avis</p>
                <div className="flex items-center gap-2 text-gray-500">
                  <Star size={18} className="text-amber-400 fill-amber-400" />
                  <span>—</span>
                  <span className="text-sm">En attente d'intégration</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* --- Header Layer --- */}
      <div className="relative z-20 pt-12 px-4 pb-2 flex flex-col pointer-events-none">
        {variant === 'groups' ? (
          // Header: Groups Mode
          <div className="flex items-center justify-between w-full">
            <div className="pointer-events-auto shadow-lg bg-white rounded-full px-1 py-1 pr-4 flex items-center gap-2 transition-transform active:scale-95">
               <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-xl">🇨🇦</div>
               <span className="font-bold text-gray-900 text-sm">Montreal</span>
            </div>
            
            <div className="flex items-center gap-3 pointer-events-auto">
              <IconButton><Eye size={20} /></IconButton>
              <div className="relative">
                <IconButton><Bell size={20} /></IconButton>
                <Badge count={1} />
              </div>
              <div onClick={() => onProfileClick(meUser)} className="cursor-pointer active:scale-95 transition-transform">
                <img src={meUser.image} className="w-10 h-10 rounded-full border-2 border-white shadow-sm object-cover" alt="Profile" />
              </div>
            </div>
          </div>
        ) : (
          // Header: Travelers Mode
          <div className="w-full flex flex-col gap-3 pointer-events-auto">
             {/* Search Bar */}
             <div className="w-full bg-white rounded-full shadow-[0_2px_15px_rgba(0,0,0,0.06)] h-12 flex items-center px-5 gap-3 border border-white/50 relative z-30">
                <Search className="text-black" size={20} strokeWidth={2.5} />
                <span className="flex-1 text-gray-900 font-semibold text-sm truncate">Montréal, Canada</span>
                {/* Profile Picture REMOVED here */}
             </div>
             
             {/* Filter Chips - Horizontal Scroll */}
             <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-2 pt-1 -ml-1 pl-1">
                <button onClick={onFilterClick} className="flex items-center gap-2 bg-white px-4 py-2 rounded-full shadow-sm border border-gray-100 active:scale-95 transition-transform shrink-0">
                  <SlidersHorizontal size={16} className="text-gray-900" strokeWidth={2.5} />
                  <span className="text-xs font-bold text-gray-900">Filter</span>
                </button>
                {filterChips.map((chip, i) => (
                  <button key={i} onClick={onFilterClick} className="flex items-center gap-2 bg-white px-4 py-2 rounded-full shadow-sm border border-gray-100 active:scale-95 transition-transform whitespace-nowrap shrink-0">
                    <span className="text-lg leading-none">{chip.emoji}</span>
                    <span className="text-xs font-bold text-gray-900">{chip.label}</span>
                  </button>
                ))}
             </div>
          </div>
        )}
      </div>

      {/* --- Floating Action Buttons (Right Side) --- */}
      <div 
        className={`absolute right-4 z-20 flex flex-col gap-4 pointer-events-auto transition-all duration-300 ease-out`}
        style={{ bottom: isSheetOpen ? `${SHEET_HEIGHT_PERCENT + 5}%` : '120px' }}
      >
         {variant === 'groups' ? (
           <>
             <button className="w-12 h-12 bg-white rounded-full shadow-lg flex items-center justify-center text-gray-800 border border-gray-100 active:scale-95 transition-transform">
                <Locate size={24} />
             </button>
             <button 
               onClick={onAddGroupClick} 
               className="w-12 h-12 bg-blue-500 rounded-full shadow-lg flex items-center justify-center text-white border border-white/20 active:scale-95 transition-transform"
             >
                <Plus size={28} />
             </button>
           </>
         ) : (
           <>
             {/* Info Icon */}
             <div className="w-12 flex justify-center">
                 <div className="w-6 h-6 rounded-full border border-blue-400 text-blue-400 flex items-center justify-center text-xs italic font-serif bg-white/50 backdrop-blur-sm">i</div>
             </div>
           </>
         )}
      </div>
      
      {/* --- Attribution --- */}
      <div 
         className={`absolute left-4 z-0 text-gray-500 text-[10px] font-bold flex items-center gap-1 opacity-60 transition-all duration-300`}
         style={{ bottom: isSheetOpen ? `${SHEET_HEIGHT_PERCENT + 3}%` : '120px' }}
      >
        <div className="w-4 h-4 rounded-full border border-gray-500 flex items-center justify-center">
            <Compass size={10} />
        </div>
        mapbox
      </div>

      {/* --- Floating "Show List" Button (When Sheet Closed) --- */}
      <div 
        className={`absolute bottom-[100px] left-1/2 transform -translate-x-1/2 z-20 transition-all duration-300 ${!isSheetOpen ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10 pointer-events-none'}`}
      >
         <button 
           onClick={() => setIsSheetOpen(true)}
           className="bg-white px-5 py-2.5 rounded-full shadow-lg border border-gray-100 flex items-center gap-2 active:scale-95 transition-transform"
         >
            <List size={20} className="text-black" />
            <span className="font-bold text-black text-sm">Show List</span>
         </button>
      </div>

      {/* --- Draggable Bottom Sheet --- */}
      <div 
        ref={sheetRef}
        className={`absolute bottom-0 left-0 right-0 bg-[#F2F4F6] rounded-t-[36px] shadow-[0_-5px_30px_rgba(0,0,0,0.05)] z-30 flex flex-col touch-none`}
        style={{ 
          height: `${SHEET_HEIGHT_PERCENT}%`,
          transform: isSheetOpen 
            ? `translateY(${Math.max(0, dragOffset)}px)` 
            : 'translateY(100%)',
          transition: isDragging ? 'none' : 'transform 0.4s cubic-bezier(0.33, 1, 0.68, 1)' 
        }}
      >
        
        {/* Drag Handle */}
        <div 
           className="w-full flex justify-center pt-3 pb-2 cursor-grab active:cursor-grabbing shrink-0"
           onTouchStart={handleTouchStart}
           onTouchMove={handleTouchMove}
           onTouchEnd={handleTouchEnd}
        >
          <div className="w-10 h-1 bg-gray-300/80 rounded-full"></div>
        </div>

        {variant === 'groups' ? (
          // Groups List Content
          <div className="px-5 pt-2 flex-1 overflow-hidden flex flex-col">
            <h2 className="text-xl font-bold text-gray-800 mb-4 shrink-0">3 Nearby Groups</h2>
            <div className="flex-1 overflow-y-auto no-scrollbar space-y-4 pb-20">
               {GROUPS.map(group => (
                 <div key={group.id} className="flex items-center gap-4 active:scale-[0.98] transition-transform">
                    <div className="relative">
                      <img src={group.image} className="w-14 h-14 rounded-full object-cover shadow-sm" />
                      {/* Avatar Stack Overlay mini */}
                      <div className="absolute -bottom-1 -right-1 bg-gray-800 rounded-full p-0.5"></div>
                    </div>
                    <div className="flex-1">
                       <h3 className="font-bold text-gray-900 text-[15px] leading-tight mb-1">{group.title}</h3>
                       <div className="flex items-center gap-2">
                          <AvatarStack avatars={group.avatars} />
                          <span className="text-xs font-medium text-gray-600 bg-white px-2 py-0.5 rounded-full shadow-sm border border-gray-100">{group.attendees} Travelers</span>
                       </div>
                    </div>
                    <ChevronRight className="text-gray-400" size={20} />
                 </div>
               ))}
            </div>
          </div>
        ) : (
          // Travelers List Content (Matches Screenshot)
          <div className="flex-1 flex flex-col pt-1 overflow-hidden">
             <div className="px-5 pb-3 shrink-0">
                <div className="flex justify-between items-center mb-4">
                   <h2 className="text-[22px] font-bold text-[#1F2937] tracking-tight">468 Nearby Travelers</h2>
                   <div className="flex items-center gap-1 text-blue-500 text-[15px] font-semibold cursor-pointer active:opacity-70">
                      See All <ChevronRight size={18} />
                   </div>
                </div>
                
                {/* Horizontal Scroll Cards */}
                <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2">
                   {USERS.map(user => (
                      <div key={user.id} onClick={() => onProfileClick(user)} className="min-w-[130px] w-[130px] h-[170px] rounded-2xl relative overflow-hidden shadow-sm flex-shrink-0 bg-gray-200 active:scale-95 transition-transform cursor-pointer">
                         <img src={user.image} className="w-full h-full object-cover" />
                         {/* Heavy Gradient for text readability */}
                         <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent"></div>
                         
                         {/* Flag */}
                         <div className="absolute top-2.5 left-2.5">
                            <span className="text-lg drop-shadow-md">{user.flag}</span>
                         </div>

                         {/* Info */}
                         <div className="absolute bottom-3 left-3 text-white">
                            <div className="flex items-center gap-1.5 mb-0.5">
                               <span className="font-bold text-sm leading-none drop-shadow-md">{user.name}</span>
                               <div className="w-2 h-2 bg-green-500 rounded-full border border-white shadow-[0_0_4px_rgba(74,222,128,1)]"></div>
                            </div>
                            <p className="text-gray-300 text-[11px] font-medium drop-shadow-sm">{user.distance}</p>
                         </div>
                      </div>
                   ))}
                </div>
             </div>
             
             {/* Big Blue Button */}
             <div className="px-5 pb-24 mt-auto shrink-0">
                <button className="w-full bg-[#3B82F6] hover:bg-blue-600 text-white font-bold text-[15px] py-4 rounded-[20px] shadow-lg shadow-blue-500/20 transition-all active:scale-[0.98]">
                  See all 468 Nearby Travelers
                </button>
             </div>
          </div>
        )}
      </div>
    </div>
  );
};

// 5. Profile Screen
interface ProfileScreenProps {
  user: any;
  onBack: () => void;
}

const ProfileScreen: React.FC<ProfileScreenProps> = ({ user, onBack }) => {
  // Mock data to match screenshot regardless of user
  // In a real app, this would come from the user prop or API
  const age = 24;
  const location = "CANADA";
  
  return (
    <div className="w-full h-full bg-white flex flex-col relative overflow-hidden">
      
      {/* 1. Full Screen Hero Image (Scrollable) */}
      <div className="flex-1 overflow-y-auto no-scrollbar relative bg-white">
          
          {/* Top Image Section */}
          <div className="w-full h-[65vh] relative shrink-0">
             <img src={user.image} className="w-full h-full object-cover" />
             
             {/* Top Overlay Gradient */}
             <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-black/50 to-transparent z-10"></div>
             
             {/* Bottom Overlay Gradient */}
             <div className="absolute bottom-0 left-0 right-0 h-64 bg-gradient-to-t from-black/90 via-black/40 to-transparent z-10"></div>

             {/* Header Buttons */}
             <div className="absolute top-0 left-0 right-0 p-4 pt-12 flex justify-between items-center z-20">
                <button onClick={onBack} className="w-10 h-10 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white active:scale-95 transition-transform">
                   <ArrowLeft size={24} />
                </button>
                <button className="w-10 h-10 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white active:scale-95 transition-transform">
                   <MoreHorizontal size={24} />
                </button>
             </div>

             {/* Hero Info Content */}
             <div className="absolute bottom-12 left-0 right-0 px-6 z-20 flex flex-col items-center text-center">
                 <div className="flex items-center gap-2 mb-1">
                     <h1 className="text-4xl font-bold text-white tracking-tight">{user.name}, {age}</h1>
                     <div className="bg-blue-500 rounded-full p-0.5">
                        <Check size={14} className="text-white" strokeWidth={4} />
                     </div>
                 </div>
                 <div className="flex items-center gap-1.5 text-white/90 font-bold tracking-wide text-xs mb-6">
                    <span className="text-lg">{user.flag}</span> {location}
                 </div>
                 
                 {/* Pagination Dots */}
                 <div className="flex gap-1.5 mb-4">
                    <div className="w-1.5 h-1.5 rounded-full bg-white"></div>
                    <div className="w-1.5 h-1.5 rounded-full bg-white/40"></div>
                 </div>
             </div>
          </div>

          {/* White Content Sheet (Overlapping) */}
          <div className="relative -mt-6 bg-white rounded-t-[32px] z-30 pt-8 px-6 pb-24 min-h-[50vh]">
             {/* Drag Indicator */}
             <div className="absolute top-3 left-1/2 -translate-x-1/2 w-10 h-1 bg-gray-200 rounded-full"></div>

             {/* Action Buttons */}
             <div className="flex gap-3 mb-10">
                <button className="flex-1 py-3.5 rounded-full border border-gray-200 flex items-center justify-center gap-2 font-bold text-gray-900 active:bg-gray-50 transition-colors">
                   <UserPlus size={20} /> Add Friend
                </button>
                <button className="flex-1 py-3.5 rounded-full border border-gray-200 flex items-center justify-center gap-2 font-bold text-gray-900 active:bg-gray-50 transition-colors">
                   <MessageSquare size={20} /> Message
                </button>
             </div>

             {/* About Me */}
             <div className="mb-8">
                <h2 className="text-lg font-bold text-gray-900 mb-2">About Me</h2>
                <p className="text-gray-500 text-[15px]">{user.name} hasn't shared anything yet 🙄</p>
             </div>

             {/* Badges */}
             <div className="mb-8">
                <h2 className="text-lg font-bold text-gray-900 mb-3">Badges</h2>
                <div className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-gray-100 shadow-sm">
                   <div className="bg-blue-500 p-0.5 rounded-full">
                      <Check size={12} className="text-white" strokeWidth={4} />
                   </div>
                   <span className="font-bold text-sm text-gray-900">Verified</span>
                </div>
             </div>

             {/* Upcoming Trips */}
             <div className="mb-8">
                <h2 className="text-lg font-bold text-gray-900 mb-3">Upcoming Trips</h2>
                <div className="bg-gray-50 p-4 rounded-2xl flex items-center gap-4">
                   <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center text-2xl shadow-sm">
                      🇵🇹
                   </div>
                   <div>
                      <div className="font-bold text-gray-900">Lisbon</div>
                      <div className="text-sm text-gray-500 font-medium">4 Mar - 16 Mar, 2026</div>
                   </div>
                </div>
             </div>

             {/* Travel Stats */}
             <div className="mb-8">
                <div className="flex justify-between items-center mb-3">
                   <h2 className="text-lg font-bold text-gray-900">Travel Stats</h2>
                   <span className="text-blue-500 text-sm font-bold flex items-center cursor-pointer">See More <ChevronRight size={16} /></span>
                </div>
                
                {/* World Map Visualization (Static Image Placeholder) */}
                <div className="w-full aspect-[16/9] mb-4 relative opacity-80">
                   <img 
                      src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/World_map_blank_without_borders.svg/2000px-World_map_blank_without_borders.svg.png" 
                      className="w-full h-full object-contain filter grayscale opacity-30" 
                      alt="World Map"
                   />
                   {/* Fake highlighted countries */}
                   <div className="absolute top-[20%] left-[20%] w-2 h-2 bg-blue-500 rounded-full"></div>
                   <div className="absolute top-[25%] left-[25%] w-3 h-3 bg-blue-500 rounded-full"></div>
                   <div className="absolute top-[30%] left-[50%] w-2 h-2 bg-blue-500 rounded-full"></div>
                </div>

                <div className="flex justify-between px-10">
                   <div className="text-center">
                      <div className="text-blue-500 text-3xl font-bold mb-1">7</div>
                      <div className="text-gray-400 text-xs font-medium">Countries</div>
                   </div>
                   <div className="text-center">
                      <div className="w-12 h-12 rounded-full border-4 border-gray-100 border-t-blue-500 rotate-45 flex items-center justify-center mx-auto mb-1">
                         <span className="-rotate-45 text-blue-500 font-bold text-sm">3%</span>
                      </div>
                      <div className="text-gray-400 text-xs font-medium">World</div>
                   </div>
                </div>
             </div>

             {/* Interests */}
             <div className="mb-8">
                <h2 className="text-lg font-bold text-gray-900 mb-3">Interests</h2>
                <div className="flex flex-wrap gap-2">
                   {[
                      { label: 'Fashion & Shopping', icon: <ShoppingBag size={14} className="text-pink-500" fill="currentColor" fillOpacity={0.2} /> },
                      { label: 'Nightlife', icon: <Building2 size={14} className="text-blue-600" fill="currentColor" fillOpacity={0.2} /> },
                      { label: 'Off-Grid Spots', icon: <Tent size={14} className="text-orange-500" fill="currentColor" fillOpacity={0.2} /> },
                      { label: 'Spontaneous Trips', icon: <Plane size={14} className="text-blue-400" fill="currentColor" fillOpacity={0.2} /> },
                      { label: 'Living Abroad', icon: <Briefcase size={14} className="text-amber-700" fill="currentColor" fillOpacity={0.2} /> }
                   ].map((interest, i) => (
                      <div key={i} className="px-4 py-2.5 rounded-full border border-gray-200 flex items-center gap-2 font-bold text-sm text-gray-800 bg-white">
                         {interest.icon} {interest.label}
                      </div>
                   ))}
                </div>
             </div>

             {/* Languages */}
             <div className="mb-8">
                <h2 className="text-lg font-bold text-gray-900 mb-3">Languages</h2>
                <div className="inline-block px-4 py-2.5 rounded-full border border-gray-200 font-bold text-sm text-gray-800 bg-white">
                   English, French, Mandarin Chinese
                </div>
             </div>
          </div>
      </div>
    </div>
  );
};

// --- Missing Components ---

const HousingScreen = () => {
  const [activeTab, setActiveTab] = useState<'spots' | 'roommates' | 'swaps'>('spots');

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="px-5 pt-12 pb-4 bg-white sticky top-0 z-10">
        <h1 className="text-2xl font-bold mb-4">Housing</h1>
        <div className="flex gap-2 overflow-x-auto no-scrollbar">
           <button
             onClick={() => setActiveTab('spots')}
             className={`px-4 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-colors ${activeTab === 'spots' ? 'bg-black text-white' : 'bg-gray-100 text-gray-600'}`}
           >
             Find a Spot
           </button>
           <button
             onClick={() => setActiveTab('roommates')}
             className={`px-4 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-colors ${activeTab === 'roommates' ? 'bg-black text-white' : 'bg-gray-100 text-gray-600'}`}
           >
             Roommates
           </button>
           <button
             onClick={() => setActiveTab('swaps')}
             className={`px-4 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-colors ${activeTab === 'swaps' ? 'bg-black text-white' : 'bg-gray-100 text-gray-600'}`}
           >
             Home Swaps
           </button>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-5 space-y-4 pb-24 no-scrollbar">
         {activeTab === 'spots' && HOUSING_SPOTS.map(spot => (
            <div key={spot.id} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100">
               <div className="h-40 relative">
                  <img src={spot.image} className="w-full h-full object-cover" />
                  <div className="absolute top-3 right-3 bg-white px-2 py-1 rounded-lg text-xs font-bold shadow-sm">
                     ★ {spot.rating}
                  </div>
               </div>
               <div className="p-4">
                  <div className="flex justify-between items-start mb-2">
                     <h3 className="font-bold text-lg leading-tight">{spot.title}</h3>
                     <div className="text-right">
                        <span className="font-bold text-blue-600">{spot.currency}{spot.price}</span>
                        <span className="text-gray-400 text-xs">/{spot.period}</span>
                     </div>
                  </div>
                  <div className="flex items-center gap-2">
                     <img src={spot.recommenderImg} className="w-6 h-6 rounded-full" />
                     <span className="text-xs text-gray-500">Recommended by <strong>{spot.recommender}</strong></span>
                  </div>
               </div>
            </div>
         ))}

         {activeTab === 'roommates' && ROOMMATES.map(person => (
            <div key={person.id} className="bg-white rounded-2xl p-4 flex gap-4 shadow-sm border border-gray-100">
               <img src={person.image} className="w-20 h-20 rounded-xl object-cover" />
               <div className="flex-1">
                  <h3 className="font-bold text-lg">{person.name}, {person.age}</h3>
                  <p className="text-sm text-gray-500 mb-2">{person.location} • ${person.budget}</p>
                  <div className="flex flex-wrap gap-1">
                     {person.tags.map(tag => (
                        <span key={tag} className="px-2 py-0.5 bg-gray-100 rounded text-[10px] font-bold text-gray-600">{tag}</span>
                     ))}
                  </div>
               </div>
            </div>
         ))}
         
         {activeTab === 'swaps' && SWAPS.map(swap => (
            <div key={swap.id} className="bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100">
               <div className="h-40 relative">
                  <img src={swap.image} className="w-full h-full object-cover" />
                  <div className="absolute bottom-3 left-3 bg-black/60 backdrop-blur-sm text-white px-3 py-1 rounded-full text-xs font-bold">
                     {swap.homeType}
                  </div>
               </div>
               <div className="p-4">
                  <h3 className="font-bold text-lg mb-1">{swap.title}</h3>
                  <div className="flex justify-between items-center text-sm text-gray-500">
                     <span>{swap.dates}</span>
                     <div className="flex items-center gap-2">
                        <span className="text-xs">Owner: {swap.owner}</span>
                        <img src={swap.ownerImg} className="w-6 h-6 rounded-full" />
                     </div>
                  </div>
               </div>
            </div>
         ))}
      </div>
    </div>
  );
};

// 7. New Chat Detail Screen (Matches screenshot with dynamic data)
interface ChatDetailScreenProps {
  chat: any;
  messages: any[];
  onSendMessage: (text: string) => void;
  onBack: () => void;
}

const ChatDetailScreen: React.FC<ChatDetailScreenProps> = ({ chat, messages, onSendMessage, onBack }) => {
   const [inputText, setInputText] = useState('');
   const scrollRef = useRef<HTMLDivElement>(null);
   
   // Hardcoded avatars for the group feel from screenshot (fallback if no specific members)
   const avatars = [
      'https://i.pravatar.cc/150?u=annie',
      'https://i.pravatar.cc/150?u=natalie',
      'https://i.pravatar.cc/150?u=omurbek'
   ];

   useEffect(() => {
     if (scrollRef.current) {
       scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
     }
   }, [messages]);

   const handleSend = () => {
     if (inputText.trim()) {
       onSendMessage(inputText);
       setInputText('');
     }
   };

   return (
      <div className="flex flex-col h-full bg-white relative">
         {/* Header */}
         <div className="pt-12 pb-3 px-4 border-b border-gray-100 flex items-center justify-between sticky top-0 bg-white z-20">
             <div className="flex items-center gap-3">
                 <button onClick={onBack} className="text-gray-900">
                    <ArrowLeft size={24} />
                 </button>
                 <div className="relative">
                    <img src={chat.image} className="w-10 h-10 rounded-full object-cover" />
                 </div>
                 <div>
                    <div className="flex items-center gap-1">
                        <h2 className="font-bold text-lg leading-none">{chat.title}</h2>
                        {chat.type === 'group' && <span className="text-base">🫶🏼</span>}
                    </div>
                    {chat.type === 'group' ? (
                       <div className="flex items-center gap-1.5 mt-0.5">
                          <AvatarStack avatars={avatars} size="sm" />
                          <span className="text-xs text-gray-500 font-medium">80 members</span>
                       </div>
                    ) : (
                       <div className="text-xs text-green-500 font-medium mt-0.5">Online</div>
                    )}
                 </div>
             </div>
             <button className="text-gray-900">
                <MoreHorizontal size={24} />
             </button>
         </div>

         {/* Messages List - Dynamic */}
         <div ref={scrollRef} className="flex-1 overflow-y-auto px-4 py-4 space-y-6 bg-white no-scrollbar pb-24">
             {messages.map((msg, index) => {
               if (msg.type === 'separator') {
                 return (
                   <div key={index} className="flex justify-center my-4">
                       <span className="text-xs font-medium text-gray-400 bg-white px-2">{msg.text}</span>
                   </div>
                 );
               }

               const isMe = msg.isMe;

               return (
                 <div key={msg.id || index} className={`flex gap-3 ${isMe ? 'flex-row-reverse' : ''}`}>
                     {!isMe && (
                        <img src={msg.senderAvatar} className="w-9 h-9 rounded-full object-cover mt-6" />
                     )}
                     <div className={`flex flex-col ${isMe ? 'items-end' : 'items-start'} max-w-[85%]`}>
                         {!isMe && (
                           <span className={`text-[11px] font-bold mb-1 ml-1 ${msg.color || 'text-gray-900'}`}>
                             {msg.sender} <span className="text-gray-300 font-normal ml-1">{msg.time}</span>
                           </span>
                         )}
                         {isMe && (
                           <span className="text-[11px] font-medium text-gray-400 mb-1 mr-1">{msg.time}</span>
                         )}

                         <div className={`
                            ${isMe ? 'bg-blue-500 text-white rounded-2xl rounded-tr-none' : 'bg-gray-100 text-gray-800 rounded-2xl rounded-tl-none'}
                            p-3.5 text-[15px] leading-snug
                         `}>
                             {msg.replyTo && (
                               <div className={`${isMe ? 'bg-blue-600/50 border-white/30' : 'bg-[#D8E2F1]/50 border-blue-400'} border-l-2 p-2 rounded-md mb-2`}>
                                   <div className={`${isMe ? 'text-blue-100' : 'text-blue-500'} font-bold text-xs mb-0.5`}>{msg.replyTo.sender}</div>
                                   <div className={`text-xs ${isMe ? 'text-blue-100/80' : 'text-gray-600'} line-clamp-2`}>{msg.replyTo.text}</div>
                               </div>
                             )}
                             {msg.text}
                         </div>
                     </div>
                 </div>
               );
             })}
         </div>

         {/* Input Area */}
         <div className="absolute bottom-0 left-0 right-0 bg-white px-4 py-3 border-t border-gray-50 pb-8">
            <div className="flex items-center gap-2">
                <input 
                  type="text" 
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                  placeholder="Type something..." 
                  className="flex-1 bg-gray-100 text-gray-900 rounded-full px-5 py-3.5 text-[15px] focus:outline-none focus:ring-1 focus:ring-gray-200 placeholder:text-gray-400" 
                />
                <button 
                  onClick={handleSend}
                  className="w-12 h-12 bg-gray-300 rounded-full flex items-center justify-center text-white shrink-0 hover:bg-blue-500 transition-colors"
                >
                   <Send size={20} className="ml-0.5 mt-0.5" fill="currentColor" />
                </button>
            </div>
         </div>
      </div>
   );
};

const ChatsScreen = ({ onChatClick }: { onChatClick: (chat: any) => void }) => {
  const [tab, setTab] = useState<'all' | 'dms' | 'plans'>('all');

  const filteredChats = CHATS.filter(chat => {
    if (tab === 'all') return true;
    if (tab === 'dms') return chat.type === 'dm';
    if (tab === 'plans') return chat.type === 'group';
    return true;
  });

  return (
    <div className="flex flex-col h-full bg-white">
      {/* Header */}
      <div className="px-5 pt-14 pb-4 flex justify-between items-center">
        <h1 className="text-3xl font-extrabold text-black">Chats</h1>
        <div className="flex items-center gap-3">
          <button className="bg-blue-100 text-blue-600 px-3 py-1.5 rounded-full text-xs font-bold transition-opacity hover:opacity-80">
            0 Requests
          </button>
          <button className="text-gray-400">
             <Search size={26} />
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-5 mb-6">
        <div className="bg-gray-100 p-1 rounded-xl flex text-sm font-semibold">
          <button 
            onClick={() => setTab('all')}
            className={`flex-1 py-1.5 rounded-lg transition-all ${tab === 'all' ? 'bg-white text-black shadow-sm' : 'text-gray-500'}`}
          >
            All
          </button>
          <button 
             onClick={() => setTab('dms')}
             className={`flex-1 py-1.5 rounded-lg transition-all ${tab === 'dms' ? 'bg-white text-black shadow-sm' : 'text-gray-500'}`}
          >
            DMs
          </button>
          <button 
             onClick={() => setTab('plans')}
             className={`flex-1 py-1.5 rounded-lg transition-all ${tab === 'plans' ? 'bg-white text-black shadow-sm' : 'text-gray-500'}`}
          >
            Plans
          </button>
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto no-scrollbar">
         {filteredChats.map(chat => (
            <div 
               key={chat.id} 
               onClick={() => onChatClick(chat)}
               className="px-5 py-3 flex gap-4 active:bg-gray-50 transition-colors cursor-pointer mb-2"
            >
               <div className="relative">
                  <img src={chat.image} className="w-14 h-14 rounded-full object-cover" />
                  {/* Unread dot in list */}
               </div>
               <div className="flex-1 min-w-0 flex flex-col justify-center">
                  <div className="flex justify-between items-center mb-0.5">
                     <h3 className="font-bold text-gray-900 text-base">{chat.title}</h3>
                     <span className="text-xs text-gray-400 font-medium">{chat.time}</span>
                  </div>
                  <div className="flex justify-between items-center">
                     <p className={`text-[15px] truncate pr-4 ${chat.unread ? 'text-gray-900 font-medium' : 'text-gray-500'}`}>{chat.message}</p>
                     {chat.unread && <div className="w-2.5 h-2.5 bg-blue-500 rounded-full flex-shrink-0"></div>}
                  </div>
               </div>
            </div>
         ))}
      </div>
    </div>
  );
};

const FilterScreen = ({ onClose }: { onClose: () => void }) => {
   return (
      <div className="fixed inset-0 z-[60] bg-black/50 backdrop-blur-sm flex items-end sm:items-center justify-center p-4">
         <div className="bg-white w-full max-w-sm rounded-3xl p-6 animate-in slide-in-from-bottom duration-300">
            <div className="flex justify-between items-center mb-6">
               <h2 className="text-xl font-bold">Filters</h2>
               <button onClick={onClose}><X size={24} /></button>
            </div>
            
            <div className="space-y-6">
               <div>
                  <label className="text-sm font-bold text-gray-900 mb-3 block">Traveler Type</label>
                  <div className="flex flex-wrap gap-2">
                     {['Backpacker', 'Digital Nomad', 'Student', 'Expat', 'Tourist'].map(t => (
                        <button key={t} className="px-4 py-2 rounded-full border border-gray-200 text-sm font-medium hover:border-blue-500 hover:text-blue-500 transition-colors">
                           {t}
                        </button>
                     ))}
                  </div>
               </div>

               <div>
                  <label className="text-sm font-bold text-gray-900 mb-3 block">Nationality</label>
                  <select className="w-full bg-gray-50 rounded-xl px-4 py-3 text-sm font-medium border-none focus:ring-2 focus:ring-blue-500">
                     <option>Any</option>
                     <option>United States</option>
                     <option>Canada</option>
                     <option>France</option>
                     <option>Germany</option>
                  </select>
               </div>
               
               <button onClick={onClose} className="w-full bg-black text-white font-bold py-4 rounded-xl mt-4">
                  Show Results
               </button>
            </div>
         </div>
      </div>
   );
};

// --- Main Layout ---

export default function App() {
  const [activeTab, setActiveTab] = useState<Tab>(Tab.EXPLORE);
  const [selectedUser, setSelectedUser] = useState<any>(null); // State for selected user profile
  const [selectedChat, setSelectedChat] = useState<any>(null); // State for selected chat
  const [chatHistory, setChatHistory] = useState<Record<number, any[]>>(CHAT_MESSAGES); // State for chat memory
  const [showFilter, setShowFilter] = useState(false);
  const [showCreateGroup, setShowCreateGroup] = useState(false); 

  const handleSendMessage = (chatId: number, text: string) => {
    const newMessage = {
      id: Date.now(),
      sender: 'Me',
      senderAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-4.0.3&auto=format&fit=crop&w=200&q=80',
      text: text,
      time: 'Now',
      isMe: true,
      color: 'text-blue-500'
    };

    setChatHistory(prev => ({
      ...prev,
      [chatId]: [...(prev[chatId] || []), newMessage]
    }));
  };

  const renderContent = () => {
    // If a user is selected, show their profile
    if (selectedUser) {
      return <ProfileScreen user={selectedUser} onBack={() => setSelectedUser(null)} />;
    }

    // If a chat is selected, show chat detail
    if (selectedChat) {
      const messages = chatHistory[selectedChat.id] || [];
      return (
        <ChatDetailScreen 
          chat={selectedChat} 
          messages={messages} 
          onSendMessage={(text) => handleSendMessage(selectedChat.id, text)}
          onBack={() => setSelectedChat(null)} 
        />
      );
    }

    switch (activeTab) {
      case Tab.EXPLORE:
        return (
          <ExploreScreen 
            variant="groups" 
            onProfileClick={(user) => setSelectedUser(user)} 
            onFilterClick={() => setShowFilter(true)} 
            onAddGroupClick={() => setShowCreateGroup(true)} 
          />
        );
      case Tab.MAP:
        return (
          <ExploreScreen 
            variant="travelers" 
            onProfileClick={(user) => setSelectedUser(user)} 
            onFilterClick={() => setShowFilter(true)} 
            onAddGroupClick={() => setShowCreateGroup(true)}
          />
        );
      case Tab.HOUSING:
        return <HousingScreen />;
      case Tab.CHATS:
        return <ChatsScreen onChatClick={(chat) => setSelectedChat(chat)} />;
      default:
        return (
          <ExploreScreen 
            variant="groups" 
            onProfileClick={(user) => setSelectedUser(user)} 
            onFilterClick={() => setShowFilter(true)} 
            onAddGroupClick={() => setShowCreateGroup(true)}
          />
        );
    }
  };

  return (
    <div className="w-full h-[100dvh] bg-white flex flex-col relative max-w-md mx-auto shadow-2xl overflow-hidden font-sans">
      
      {/* Main Content Area */}
      <div className="flex-1 relative overflow-hidden">
        {renderContent()}
      </div>

      {/* Modals */}
      {showFilter && <FilterScreen onClose={() => setShowFilter(false)} />}
      {showCreateGroup && <CreateGroupFlow onClose={() => setShowCreateGroup(false)} />}

      {/* Bottom Navigation */}
      {/* Hide bottom nav when viewing a profile or chat detail */}
      {!selectedUser && !selectedChat && (
        <div className="absolute bottom-0 left-0 right-0 bg-white border-t border-gray-100 pt-3 pb-8 px-6 flex justify-between items-center z-50">
          <button 
            onClick={() => { setActiveTab(Tab.EXPLORE); }}
            className={`flex flex-col items-center gap-1 transition-colors active:scale-95 ${activeTab === Tab.EXPLORE ? 'text-blue-500' : 'text-gray-400'}`}
          >
            <Globe size={26} strokeWidth={activeTab === Tab.EXPLORE ? 2.5 : 2} />
          </button>

          <button 
            onClick={() => { setActiveTab(Tab.MAP); }}
            className={`relative flex flex-col items-center gap-1 transition-colors active:scale-95 ${activeTab === Tab.MAP ? 'text-blue-500' : 'text-gray-400'}`}
          >
            <MapPin size={26} strokeWidth={activeTab === Tab.MAP ? 2.5 : 2} />
            {/* Notification Dot for Map Pin */}
            <div className="absolute top-0 right-0 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white translate-x-1/3 -translate-y-1/3"></div>
          </button>

          <button 
            onClick={() => { setActiveTab(Tab.HOUSING); }}
            className={`flex flex-col items-center gap-1 transition-colors active:scale-95 ${activeTab === Tab.HOUSING ? 'text-blue-500' : 'text-gray-400'}`}
          >
            <Home size={26} strokeWidth={activeTab === Tab.HOUSING ? 2.5 : 2} />
          </button>

          <button 
            onClick={() => { setActiveTab(Tab.CHATS); }}
            className={`flex flex-col items-center gap-1 transition-colors active:scale-95 ${activeTab === Tab.CHATS ? 'text-blue-500' : 'text-gray-400'}`}
          >
            <MessageSquare size={26} strokeWidth={activeTab === Tab.CHATS ? 2.5 : 2} />
          </button>
        </div>
      )}

    </div>
  );
}