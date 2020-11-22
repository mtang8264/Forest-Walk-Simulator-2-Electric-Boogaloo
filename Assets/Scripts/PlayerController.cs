using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [SerializeField]
    float walkSpeed;

    Rigidbody rb;

    void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    void Update()
    {
        if(Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.D))
        {
            Turn();
        }
    }

    void FixedUpdate()
    {
        Walk();
    }

    void Turn()
    {
        Vector3 l = Vector3.Lerp(transform.position + transform.forward, transform.position + TargetDirection(), 0.05f);
        transform.LookAt(l);
    }

    Vector3 TargetDirection()
    {
        Vector3 d = new Vector3();
        if (Input.GetKey(KeyCode.W))
        {
            d += CameraControls.inst.Forward;
        }
        if (Input.GetKey(KeyCode.S))
        {
            d -= CameraControls.inst.Forward;
        }
        if(Input.GetKey(KeyCode.D))
        {
            d += Quaternion.Euler(0, 90, 0) * CameraControls.inst.Forward;
        }
        if(Input.GetKey(KeyCode.A))
        {
            d -= Quaternion.Euler(0, 90, 0) * CameraControls.inst.Forward;
        }
        d.Normalize();
        return d;
    }

    void Walk()
    {
        float m = Mathf.Abs(Input.GetAxis("Horizontal")) + Mathf.Abs(Input.GetAxis("Vertical"));
        m = m > 1f ? 1 : m;
        Debug.Log(m);
        rb.MovePosition(transform.position + (transform.forward * Time.deltaTime * walkSpeed * m));
    }
}
