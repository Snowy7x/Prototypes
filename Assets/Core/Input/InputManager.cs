using System;
using UnityEngine;
using UnityEngine.InputSystem;

namespace Core
{
    public enum InputVersion { OldInput, NewInput }
 
    public class InputManager : MonoBehaviour
    {
        public static InputManager Instance { get; private set; }
        [SerializeField] private InputVersion inputVersion;
        private PlayerInput playerInput;
    
        public float Horizontal { get; private set; }
        public float Vertical { get; private set; }

        public float MouseWheel { get; private set; }
        
        public Vector2 Look { get; private set; }
        
        public ButtonState Jump { get; private set; }
        public ButtonState Sprint { get; private set; }
        public ButtonState Crouch { get; private set; }
        public ButtonState Interact { get; private set; }
        public ButtonState Attack { get; private set; }
        public ButtonState Aim { get; private set; }
        
        public ButtonState Reload { get; private set; }
        
        public event Action<Vector2> OnMove;
        public event Action<Vector2> OnLook;
        public event Action<ButtonState> OnJump;
        public event Action<ButtonState> OnSprint;
        public event Action<ButtonState> OnCrouch;
        public event Action<ButtonState> OnInteract;
        public event Action<ButtonState> OnAttack;
        public event Action<ButtonState> OnReload;
        public event Action<ButtonState> OnAim;
        public event Action<float> OnMouseWheel;

        public bool IsJump => Jump == ButtonState.Held || Jump == ButtonState.Pressed;
        public bool IsSprint => Sprint == ButtonState.Held || Sprint == ButtonState.Pressed;
        public bool IsCrouch => Crouch == ButtonState.Held || Crouch == ButtonState.Pressed;
        public bool IsAttack => Attack == ButtonState.Held || Attack == ButtonState.Pressed;
        public bool IsAim => Aim == ButtonState.Held || Aim == ButtonState.Pressed;
        public bool IsReload => Reload == ButtonState.Held || Aim == ButtonState.Pressed;
        
        private bool _jump;
        private bool _sprint;
        private bool _crouch;
        private bool _interact;
        private bool _reload;
        private bool _attack;
        private bool _aim;
        
        private void Awake()
        {
            if (Instance == null)
                Instance = this;
            else
                Destroy(gameObject);
            
            DontDestroyOnLoad(gameObject);
        }

        private void Start()
        {
            switch (inputVersion)
            {
                case InputVersion.OldInput:
                    break;
                case InputVersion.NewInput:
                    if (playerInput == null)
                        playerInput = GetComponent<PlayerInput>();
                    if (playerInput == null)
                        Debug.LogError("PlayerInput component not found on " + gameObject.name);
                    else
                    {
                        playerInput.notificationBehavior = PlayerNotifications.InvokeCSharpEvents;
                        playerInput.onActionTriggered += OnActionTriggered;
                    }

                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        private void OnActionTriggered(InputAction.CallbackContext obj)
        {
            string actionName = obj.action.name;
            switch (actionName)
            {
                case "Move":
                    Horizontal = obj.ReadValue<Vector2>().x;
                    Vertical = obj.ReadValue<Vector2>().y;
                    break;
                /*case "Look":
                    Look = obj.ReadValue<Vector2>();
                    break;*/
                case "Mouse X":
                    Look = new Vector2(obj.ReadValue<float>(), Look.y);
                    break;
                
                case "Mouse Y":
                    Look = new Vector2(Look.x, obj.ReadValue<float>());
                    break;
                
                case "Jump":
                    _jump = obj.ReadValue<float>() > 0;
                    break;
                case "Sprint":
                    _sprint = obj.ReadValue<float>() > 0;
                    break;
                case "Crouch":
                    _crouch = obj.ReadValue<float>() > 0;
                    break;
                case "Interact":
                    _interact = obj.ReadValue<float>() > 0;
                    break;
                case "Reload":
                    _reload = obj.ReadValue<float>() > 0;
                    break;
                case "Attack":
                    _attack = obj.ReadValue<float>() > 0;
                    break;
                case "Aim":
                    _aim = obj.ReadValue<float>() > 0;
                    break;
                case "MouseWheel":
                    MouseWheel = obj.ReadValue<float>();
                    if (MouseWheel > 0)
                        OnMouseWheel?.Invoke(1);
                    else if (MouseWheel < 0)
                        OnMouseWheel?.Invoke(-1);
                    break;
                    
            }
        }

        private void Update()
        {
            if (inputVersion == InputVersion.OldInput)
            {
                OldInput();
            }
            
            UpdateEvents();
        }

        private void OldInput()
        {
            Horizontal = UnityEngine.Input.GetAxis("Horizontal");
            Vertical = UnityEngine.Input.GetAxis("Vertical");
            
            Look = new Vector2(UnityEngine.Input.GetAxis("Mouse X"), UnityEngine.Input.GetAxis("Mouse Y"));
            
            _jump = UnityEngine.Input.GetButton("Jump");
            //_sprint = UnityEngine.Input.GetButton("Sprint");
            //_crouch = UnityEngine.Input.GetButton("Crouch");
            //_interact = UnityEngine.Input.GetButton("Interact");
            //_reload = UnityEngine.Input.GetButton("Reload");
            //_attack = UnityEngine.Input.GetButton("Attack");
            //_aim = UnityEngine.Input.GetButton("Aim");
            
            if (UnityEngine.Input.GetAxis("Mouse ScrollWheel") > 0)
                OnMouseWheel?.Invoke(1);
            else if (UnityEngine.Input.GetAxis("Mouse ScrollWheel") < 0)
                OnMouseWheel?.Invoke(-1);
        }

        void UpdateEvents()
        {
            Vector2 move = new Vector2(Horizontal, Vertical);
            OnMove?.Invoke(move);
            
            Vector2 look = Look;
            OnLook?.Invoke(look);

            if (_jump && Jump == ButtonState.None)
            {
                Jump = ButtonState.Pressed;
                OnJump?.Invoke(Jump);
            }else if (_jump && Jump == ButtonState.Pressed) {
                Jump = ButtonState.Held;
                OnJump?.Invoke(Jump);
            }else if (!_jump && Jump == ButtonState.Held)
            {
                Jump = ButtonState.Released;
                OnJump?.Invoke(Jump);
            }
            else if (_jump && Jump == ButtonState.Held) {
                Jump = ButtonState.Held;
                OnJump?.Invoke(Jump);
            }else if (!_jump && Jump == ButtonState.Released) {
                Jump = ButtonState.None;
                OnJump?.Invoke(Jump);
            }
            
            if (_sprint && Sprint == ButtonState.None)
            {
                Sprint = ButtonState.Pressed;
                OnSprint?.Invoke(Sprint);
            }else if (_sprint && Sprint == ButtonState.Pressed) {
                Sprint = ButtonState.Held;
                OnSprint?.Invoke(Sprint);
            }else if (!_sprint && Sprint == ButtonState.Held) {
                Sprint = ButtonState.Released;
                OnSprint?.Invoke(Sprint);
            }else if (_sprint && Sprint == ButtonState.Held) {
                Sprint = ButtonState.Held;
                OnSprint?.Invoke(Sprint);
            }
            else if (!_sprint && Sprint == ButtonState.Released) {
                Sprint = ButtonState.None;
                OnSprint?.Invoke(Sprint);
            }
            
            if (_crouch && Crouch == ButtonState.None) Crouch = ButtonState.Pressed;
            else if (_crouch && Crouch == ButtonState.Pressed) Crouch = ButtonState.Held;
            else if (!_crouch && Crouch == ButtonState.Held) Crouch = ButtonState.Released;
            else if (_crouch && Crouch == ButtonState.Held) Crouch = ButtonState.Held;
            else if (!_crouch && Crouch == ButtonState.Released) Crouch = ButtonState.None;
            OnCrouch?.Invoke(Crouch);
            
            if (_interact && Interact == ButtonState.None) Interact = ButtonState.Pressed;
            else if (_interact && Interact == ButtonState.Pressed) Interact = ButtonState.Held;
            else if (!_interact && Interact == ButtonState.Held) Interact = ButtonState.Released;
            else if (_interact && Interact == ButtonState.Held) Interact = ButtonState.Held;
            else if (!_interact && Interact == ButtonState.Released) Interact = ButtonState.None;
            
            OnInteract?.Invoke(Interact);
            
            if (_reload && Reload == ButtonState.None) Reload = ButtonState.Pressed;
            else if (_reload && Reload == ButtonState.Pressed) Reload = ButtonState.Held;
            else if (!_reload && Reload == ButtonState.Held) Reload = ButtonState.Released;
            else if (_reload && Reload == ButtonState.Held) Reload = ButtonState.Held;
            else if (!_reload && Reload == ButtonState.Released) Reload = ButtonState.None;
            
            OnInteract?.Invoke(Reload);
            
            if (_attack && Attack == ButtonState.None) Attack = ButtonState.Pressed;
            else if (_attack && Attack == ButtonState.Pressed) Attack = ButtonState.Held;
            else if (!_attack && Attack == ButtonState.Held) Attack = ButtonState.Released;
            else if (_attack && Attack == ButtonState.Held) Attack = ButtonState.Held;
            else if (!_attack && Attack == ButtonState.Released) Attack = ButtonState.None;
            
            OnAttack?.Invoke(Attack);
            
            if (_aim && Aim == ButtonState.None) Aim = ButtonState.Pressed;
            else if (_aim && Aim == ButtonState.Pressed) Aim = ButtonState.Held;
            else if (!_aim && Aim == ButtonState.Held) Aim = ButtonState.Released;
            else if (_aim && Aim == ButtonState.Held) Aim = ButtonState.Held;
            else if (!_aim && Aim == ButtonState.Released) Aim = ButtonState.None;
             
            OnAim?.Invoke(Aim);
            
            if (_reload && Reload == ButtonState.None) Reload = ButtonState.Pressed;
            else if (_reload && Reload == ButtonState.Pressed) Reload = ButtonState.Held;
            else if (!_reload && Reload == ButtonState.Held) Reload = ButtonState.Released;
            else if (_reload && Reload == ButtonState.Held) Reload = ButtonState.Held;
            else if (!_reload && Reload == ButtonState.Released) Reload = ButtonState.None;
             
            OnReload?.Invoke(Reload);
            
            
        }
    }
    /*public class InputManager :  MonoBehaviour
    {
    
        public static InputManager instance;
        
        public bool useOldInputSystem = false;

        [SerializeField, EnableIf(nameof(useOldInputSystem))]
        InputData inputData;

        private PlayerInput m_playerInput;

        public PlayerInput playerInput
        {
            get
            {
                if (m_playerInput == null)
                    m_playerInput = GetComponent<PlayerInput>();
                return m_playerInput;
            }
        }

        // Events array
        public List<PlayerInput.ActionEvent> events;
        
        private void Awake()
        {
            if (instance == null)
                instance = this;
            else
                Destroy(gameObject);
        }

        private void Start()
        {
            if (useOldInputSystem)
            {
                // Initialize the input data

                return;
            }

            // Initialize the new input system
            if (playerInput == null)
            {
                Debug.LogError("No PlayerInput component found on the InputManager gameobject");
                return;
            }
        }

        private void OnEnable()
        {
            events = new List<PlayerInput.ActionEvent>();
            
            // Initialize the events
            foreach (var action in playerInput.actions)
            {
                //Debug.Log($"Adding event for action {action.name}");
                PlayerInput.ActionEvent e = new PlayerInput.ActionEvent(action.id, action.name);
                action.performed += e.Invoke;
                action.canceled += e.Invoke;
                action.started += e.Invoke;
                
                e.AddListener(OnAction);
                events.Add(e);
            }
        }

        private void OnDisable()
        {
            // Unsubscribe from all events
            foreach (var action in playerInput.actions)
            {
                var e = events.FirstOrDefault(x => x.actionId == action.id.ToString());
                if (e == null)
                    continue;
                
                //Debug.Log($"Removing event for action {action.name}");
                action.performed -= e.Invoke;
                action.canceled -= e.Invoke;
                action.started -= e.Invoke;
                
                e.RemoveListener(OnAction);
            }
        }
        
        private void OnAction(InputAction.CallbackContext context)
        {
            //Debug.Log($"Action {context.action.name} triggered");
            
        }
        
        public void AddListener(string actionName, UnityAction<InputAction.CallbackContext> callback)
        {
            var e = events.FirstOrDefault(x => x.actionName == actionName);
            if (e == null)
            {
                Debug.LogError($"Event for action {actionName} not found or action not registered");
                return;
            }
            
            e.AddListener(callback);
        }
    }*/
}