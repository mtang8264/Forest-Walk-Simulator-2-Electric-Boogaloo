using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraControls : MonoBehaviour
{
    [SerializeField]
    Transform player;   // The player so we can center the camera on them.
    [SerializeField]
    Vector3 centerOffset;   // The offset so the camera isn't necassarily center on the center of the model and can be focused on the head of the player.

    [SerializeField]
    float targetDistance;   // The target or max distance the camera can be from the center offset.

    Vector3 targetPos;  // The position the camera wants to move to. Important because movement happens in update but the calculation of this point is done in FixedUpdate.

    Vector3 camDir = new Vector3(0,0,-1);   // The direction from the player the camera is currently located in.

    [SerializeField]
    Vector2 rotationMultipliers;    // Multipliers to allow the rotation speed of the camera to be tuned.

    public Vector3 Forward { get { Vector3 f = player.position - transform.position; f.y = 0f; f.Normalize(); return f; } }

    void Update()
    {
        // Rotate the camera direction around the X and then Y axis.
        // The Mouse Y axis rotates around the X axis because horizontal movement rotates around a vertical axis and vice versa.
        camDir = Quaternion.AngleAxis(-Input.GetAxis("Mouse Y") * rotationMultipliers.y, Vector3.right) * camDir;
        camDir = Quaternion.AngleAxis(Input.GetAxis("Mouse X") * rotationMultipliers.x, Vector3.up) * camDir;
        camDir = camDir.normalized;

        // If the Y rotation is too great in either direction we clamp it.
        // This prevents the player from reach perfectly vertical camera positions which can be disorienting.
        if (camDir.y > 0.85f) camDir.y = 0.85f;
        if (camDir.y < -0.85f) camDir.y = -0.85f;
        camDir = camDir.normalized;

        // Move to the target position that is set in the FixedUpdate function and looks at the center.
        transform.position = targetPos;
        transform.LookAt(player.position + centerOffset);
    }

    void FixedUpdate()
    {
        // Raycast from the player center offset in the direction the camera should be placed and check for any objects in the way.
        RaycastHit hit = new RaycastHit();
        Ray r = new Ray(player.position + centerOffset, camDir);
        int mask = 1 << 9;
        Physics.Raycast(r, out hit, targetDistance, mask);

        // If nothing is hit the target position is just in the direction the full distance.
        if(hit.collider == null)
        {
            targetPos = player.position + centerOffset + camDir * (targetDistance);
        }
        // If there is an object in the way the target position stops where it hit an object.
        else
        {
            targetPos = player.position + centerOffset + camDir * (hit.distance);
        }
    }
}
